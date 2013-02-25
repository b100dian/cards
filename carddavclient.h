#ifndef CARDDAVCLIENT_H
#define CARDDAVCLIENT_H

#include <QObject>
#include <QUrl>
#include <QStringList>
#include <QNetworkAccessManager>
#include <QNetworkReply>


class CardDavClient : public QObject
{
    Q_OBJECT
    class Impl;

public:
    explicit CardDavClient(QUrl baseURL, QObject *parent = 0);

    Q_INVOKABLE void getCardNamesAsync();
    Q_INVOKABLE void getCardAsync(QString cardName);

signals:
    void error(QString message);
    void cardNames(QStringList names);
    void card(QString cardName, QString card);

private:
    QUrl baseURL;
    QNetworkAccessManager networkAccessManager;
    Impl* impl;

private slots:
    void authenticationRequired(QNetworkReply* reply, QAuthenticator* authenticator);
    void replyError(QNetworkReply::NetworkError networkError);
    void replyFinished(QNetworkReply* reply);

};

#endif // CARDDAVCLIENT_H
