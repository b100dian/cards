#include <QtGui/QApplication>
#include "qmlapplicationviewer.h"
#include "carddavclient.h"
#include <QtDeclarative/QDeclarativeContext>
#include <QUrl>

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));

    QmlApplicationViewer viewer;

    // TODO This is another URL apart from accountURL in JavaScript!!
    viewer.rootContext()->setContextProperty("cardDavClient",
        new CardDavClient(QUrl("https://google.com/.well-known/carddav"), &viewer));
//      new CardDavClient(QUrl("https://www.google.com/calendar/dav"), &viewer));

    viewer.setMainQmlFile(QLatin1String("qml/Cards/main.qml"));
    viewer.showExpanded();

    return app->exec();
}
