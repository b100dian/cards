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

        qDebug()  << "Querying " << verb << ":" << expl->baseURL << " and " << path  << "!\n for:\n"
                     << payloadString;

        QUrl url = expl->baseURL;
        if (!path.isEmpty()) {
            url.setPath(url.path() + "/" + path);
        }

        QNetworkRequest request(url);

        request.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");
        request.setRawHeader("Accept", "*/*");
        request.setRawHeader("User-Agent", "curl/7.32.0");
        request.setRawHeader("Host", "google.com");
        if (!payloadString.isEmpty()) {
            request.setHeader(QNetworkRequest::ContentLengthHeader, payloadBytes.size());
        }

        for(QMap<QString,QString>::const_iterator i = headers.constBegin();
            i != headers.constEnd(); ++i) {
            request.setRawHeader(i.key().toUtf8(), i.value().toUtf8());
        }

        if (expl->token().isEmpty()){
            request.setRawHeader("Authorization", "Basic " + QByteArray(QString("%1:%2").arg(expl->username()).arg(expl->password()).toAscii().toBase64()));
        } else {
            request.setRawHeader("Authorization", "Bearer " + expl->token().toAscii());
        }

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

    void propfindStart(QString payload = QString()) {
        QMap<QString, QString> headers;
        headers["Depth"] = "1";

        query("PROPFIND", headers, payload);
    }

    void propfindFinished(QNetworkReply* reply) {
        QXmlQuery queryCards;
        QXmlQuery queryHref;
        QStringList output;

        QString wholeReply(reply->readAll());
        qDebug() << wholeReply;

        if (!expl->isHaveURL()) {
            queryHref.setFocus(wholeReply);
            queryHref.setQuery("declare default element namespace \"DAV:\"; /multistatus/response/href/string()");
            if (!queryHref.evaluateTo(&output) || output.length() < 1) {
                qDebug()<<output;
                emit expl->error("Error Evaluating href Query");
            } else {
                expl->overrideRelativePath(output[0]);
                // loop back
                propfindStart();
            }
        } else {
            queryCards.setFocus(wholeReply);
            queryCards.setQuery("declare default element namespace \"DAV:\"; /multistatus/response/propstat/prop/concat(displayname/string(),'`',getetag/string())");

            if (!queryCards.evaluateTo(&output) || !output.length()) {
                expl->error("Error evaluating cards query");
            } else {
                emit expl->cardNames(output);
            }
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

    void reportStart(){
        QString payload("<D:propfind xmlns:D=\"DAV:\" xmlns:C=\"urn:ietf:params:xml:ns:carddav\">\n"
                        "<D:prop>\n"
                        "<D:getetag />\n"
                        "<D:name />\n"
                        "</D:prop>\n"
                        "</D:propfind>");
        query("REPORT", QMap<QString,QString>(), payload);
    }

    void reportFinished(QNetworkReply* reply) {
        qDebug() << "REPORT body ";
        qDebug() << reply->readAll();
    }
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
    //It seems GET is not redirected anymore, nor OPTIONS, only propfind
    //impl->getRedirect();
    impl->propfindStart();
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

void CardDavClient::setToken(QString token) {
    this->_token = token;
}

QString CardDavClient::password() {
    return this->_password;
}

QString CardDavClient::username() {
    return this->_username;
}

QString CardDavClient::token() {
    return this->_token;
}

void CardDavClient::authenticationRequired(QNetworkReply* reply, QAuthenticator* authenticator) {
    qDebug() << "authentication required ";
    authenticator->setUser(_username);
    authenticator->setPassword(_password);
}

void CardDavClient::replyError(QNetworkReply::NetworkError networkError) {
    emit error(QString("Reply error %1").arg(networkError));
}

void CardDavClient::overrideRelativePath(QString path) {
    _haveURL = true;
    baseURL.setPath(path);
}

bool CardDavClient::isHaveURL() {
    return _haveURL;
}

void CardDavClient::replyFinished(QNetworkReply* reply) {
    QString requestVerb(reply->request().attribute(QNetworkRequest::CustomVerbAttribute).toString());
    QUrl redirectUrl(reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl());

    if (!redirectUrl.isEmpty()) {
        qDebug()<<"Redirected to:"<<redirectUrl.path();
        // replay (yes, with an a) everything with new URL
        QString what = redirectUrl.path();
        what.chop(1);
        overrideRelativePath(what);
        if (requestVerb == "PROPFIND") {
            impl->propfindStart(QString() + "<?xml version=\"1.0\" encoding=\"UTF-8\" ?> " +
                                "<D:propfind xmlns:D=\"DAV:\" xmlns:C=\"urn:ietf:params:xml:ns:carddav\"> <D:prop> <D:getetag /> <D:name /> </D:prop> </D:propfind>");
        } else if (requestVerb == "OPTIONS") {
            impl->optionsStart();
        } else if (requestVerb == "REPORT") {
            impl->reportStart();
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

