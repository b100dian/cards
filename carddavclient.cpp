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

        if (!payloadString.isEmpty()) {
            request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml; charset=\"utf-8\"");
            request.setHeader(QNetworkRequest::ContentLengthHeader, payloadBytes.size());
        }

        for(QMap<QString,QString>::const_iterator i = headers.constBegin();
            i != headers.constEnd(); ++i) {
            request.setRawHeader(i.key().toUtf8(), i.value().toUtf8());
        }

        QString header;
        foreach(header, request.rawHeaderList()) qDebug() << header << "!" << request.rawHeader(header.toLocal8Bit());

        QNetworkReply *reply = expl->networkAccessManager.sendCustomRequest(request, verb.toAscii(), payload);

        connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), expl, SLOT(replyError(QNetworkReply::NetworkError)));
    }

public:
    explicit Impl(CardDavClient* parent = 0): expl(parent) {}

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
            emit expl->error("Error Evaluating query");
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
        emit expl->card(file,reply->readAll());
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
    impl->optionsStart();
}

void CardDavClient::getCardAsync(QString cardName) {
    impl->getStart(cardName);
}

void CardDavClient::authenticationRequired(QNetworkReply* reply, QAuthenticator* authenticator) {
    qDebug() << "authentication required ";
    authenticator->setUser(QString("b100dian"));
    authenticator->setPassword(QString("hmmtybkyzcbtlcjo"));
}

void CardDavClient::replyError(QNetworkReply::NetworkError networkError) {
    emit error(QString("reply error ") + networkError);
}

void CardDavClient::replyFinished(QNetworkReply* reply) {
    QString requestVerb(reply->request().attribute(QNetworkRequest::CustomVerbAttribute).toString());
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

