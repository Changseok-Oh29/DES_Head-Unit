#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>
#include <QTimer>
#include "caninterface.h"
#include "dbusreceiver.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // Connect to QML engine warnings/errors
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError> &warnings) {
        for (const QQmlError &warning : warnings) {
            Q_UNUSED(warning);
        }
    });

    engine.addImportPath("qrc:/");

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/Design/Constants.qml")),
                             "Design", 1, 0, "Constants");

    // Register C++ objects to QML context
    CanInterface canInterface;
    engine.rootContext()->setContextProperty("canInterface", &canInterface);

    DBusReceiver dbusReceiver;
    engine.rootContext()->setContextProperty("dbusReceiver", &dbusReceiver);

    const QUrl url(QStringLiteral("qrc:/DesignContent/App.qml"));

    // Handle QML loading failure
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [&dbusReceiver, url](QObject *obj, const QUrl &objUrl) {
                         if (url == objUrl) {
                             if (!obj) {
                                 QCoreApplication::exit(-1);
                             } else {
                                 QTimer::singleShot(2000, &dbusReceiver, &DBusReceiver::requestInitialStatus);
                             }
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    // Check if QML root objects were created
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    // Connect to CAN interface
    if (canInterface.connectToCan("can0")) {
        canInterface.startReceiving();
    }

    return app.exec();
}
