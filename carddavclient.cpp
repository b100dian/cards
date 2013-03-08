#include "carddavclient.h"
#include <QNetworkRequest>
#include <QDebug>
#include <QAuthenticator>
#include <QBuffer>
#include <QXmlQuery>
#include <QXmlResultItems>
#include <QDir>


class CardDavClient::Impl{

    CardDavClient *expl;

    void query(QString verb, QMap<QString,QString> headers = QMap<QString,QString>(), QString payloadString = QString()) {
        query(verb, QString(), headers, payloadString);
    }

    void query(QString verb, QString path, QMap<QString,QString> headers = QMap<QString,QString>(), QString payloadString = QString()) {
        QByteArray payloadBytes(payloadString.toUtf8());

        QBuffer* payload = new QBuffer(expl);
        payload->write(payloadBytes);
        payload->open(QBuffer::ReadWrite);
        payload->seek(0);

        QUrl url = expl->baseURL;
        if (!path.isEmpty()) {
            url.setPath(url.path() + "/" + path);
        }

        QNetworkRequest request(url);

        request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml; charset=\"utf-8\"");
        if (!payloadString.isEmpty()) {
            request.setHeader(QNetworkRequest::ContentLengthHeader, payloadBytes.size());
        }

        for(QMap<QString,QString>::const_iterator i = headers.constBegin();
            i != headers.constEnd(); ++i) {
            request.setRawHeader(i.key().toUtf8(), i.value().toUtf8());
        }

        request.setRawHeader("Authorization", "Basic " + QByteArray(QString("%1:%2").arg(expl->username()).arg(expl->password()).toAscii().toBase64()));

        QString header;
        foreach(header, request.rawHeaderList()) qDebug() << header << "!" << request.rawHeader(header.toLocal8Bit());

        QNetworkReply *reply = expl->networkAccessManager.sendCustomRequest(request, verb.toAscii(), payload);

        connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), expl, SLOT(replyError(QNetworkReply::NetworkError)));
    }

public:
    explicit Impl(CardDavClient* parent = 0): expl(parent) {}

    void getRedirect() {
        QMap<QString, QString> headers;
        headers["Accept"] = "*/*";

        query("GET", QString(), headers);
    }

    void optionsStart() {
        query("OPTIONS");
    }

    void optionsFinished(QNetworkReply* reply) {

        QList<QByteArray> headerList = reply->rawHeaderList();
        QByteArray header;
        bool hasPropfind = false;

        foreach (header, headerList) {
            if (QString(reply->rawHeader(header)).contains(QString("PROPFIND"))) {
                hasPropfind = true;
            }
        }

        if (hasPropfind) {
            propfindStart();
        } else {
            emit expl->error("The server doesn't do PROPFIND.");
        }
    }

    void propfindStart() {
        QMap<QString, QString> headers;
        headers["Depth"] = "1";

        query("PROPFIND", headers);
    }

    void propfindFinished(QNetworkReply* reply) {
        QXmlQuery query;
        QStringList output;
        query.setFocus(reply->readAll());
        query.setQuery("declare default element namespace \"DAV:\"; /multistatus/response/propstat/prop/displayname/string()");

        if (!query.evaluateTo(&output)) {
            emit expl->error("Error Evaluating XML Query");
        } else {
            emit expl->cardNames(output);
        }
    }

    void getStart(QString path) {
        QUrl url = expl->baseURL;
        if (!path.isEmpty()) {
            url.setPath(url.path() + path);
        }

        QNetworkRequest request(url);

        QNetworkReply *reply = expl->networkAccessManager.get(request);

        connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), expl, SLOT(replyError(QNetworkReply::NetworkError)));
    }

    void getFinished(QNetworkReply* reply) {
        QDir path(expl->baseURL.path());
        QString file = path.relativeFilePath(reply->request().url().path());
        if (reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == 200) {
            emit expl->card(file,reply->readAll());
        } else {
            qDebug()<<"GET finished with code "<< reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt()
                <<" for request " << reply->request().url().path();
        }
    }

#ifdef CARD_REPORT
    void reportStart(){
        QString payload("<?xml version=\"1.0\" encoding=\"utf-8\" ?>"
                       "<C:addressbook-query xmlns:D=\"DAV:\""
                       "                xmlns:C=\"urn:ietf:params:xml:ns:carddav\">"
                       "    <D:prop>"
                       "        <D:getetag/>"
                       "        <C:address-data content-type=\"application/vcard+xml\" version=\"2.0\"/>"
                       "    </D:prop>"
                       "    <C:filter/>"
                       "</C:addressbook-query>"
                     );
        query("REPORT", QMap<QString,QString>(), payload);
    }

    void reportFinished(QNetworkReply* reply) {
        qDebug() << "REPORT body ";
        qDebug() << reply->readAll();
    }
#endif
};

CardDavClient::CardDavClient(QUrl url, QObject *parent) :
    QObject(parent), baseURL(url), networkAccessManager(this)
{
    this->impl = new Impl(this);

    connect(&networkAccessManager, SIGNAL(authenticationRequired(QNetworkReply*,QAuthenticator*)),
            this, SLOT(authenticationRequired(QNetworkReply*,QAuthenticator*)));

    connect(&networkAccessManager, SIGNAL(finished(QNetworkReply*)),
            this, SLOT(replyFinished(QNetworkReply*)));

}

void CardDavClient::getCardNamesAsync()
{
    impl->getRedirect();
}

void CardDavClient::getCardAsync(QString cardName) {
    impl->getStart(cardName);
}

void CardDavClient::setUsername(QString username) {
    this->_username = username;
}

void CardDavClient::setPassword(QString password) {
    this->_password = password;
}

QString CardDavClient::password() {
    return this->_password;
}

QString CardDavClient::username() {
    return this->_username;
}

void CardDavClient::authenticationRequired(QNetworkReply* reply, QAuthenticator* authenticator) {
    qDebug() << "authentication required ";
    authenticator->setUser(_username);
    authenticator->setPassword(_password);
}

void CardDavClient::replyError(QNetworkReply::NetworkError networkError) {
    emit error(QString("Reply error %1").arg(networkError));
}

void CardDavClient::replyFinished(QNetworkReply* reply) {
    QString requestVerb(reply->request().attribute(QNetworkRequest::CustomVerbAttribute).toString());
    QUrl redirectUrl(reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl());

    if (!redirectUrl.isEmpty()) {
        if (requestVerb != "GET") {
            emit error(QString("Unexpected redirect while requesting for ") + requestVerb + QString(" ") + reply->request().url().toString());
        } else {
            qDebug()<<"Redirected to:"<<redirectUrl.path();
            // replay (yes with an a) everything with new URL
            baseURL.setPath(redirectUrl.path());
            impl->optionsStart();
        }
    } else if (reply->error()) {
        qDebug () << "Hopefully this already got logged:" << reply->errorString();
    } else {

        if (requestVerb == "OPTIONS") {
            impl->optionsFinished(reply);
        } else if (requestVerb == "PROPFIND") {
            impl->propfindFinished(reply);
#ifdef CARD_REPORT
        } else if (requestVerb == "REPORT") {
            impl->reportFinished(reply);
#endif
        } else {
            impl->getFinished(reply);
        }
    }
}

