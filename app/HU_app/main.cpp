#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>

#include "mediamanager.h"
#include "ipcmanager.h"
#include "services/MockVehicleService.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    
    QGuiApplication app(argc, argv);
    app.setApplicationName("HeadUnit");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    
    // Register QML types
    qmlRegisterType<MediaManager>("HeadUnit", 1, 0, "MediaManager");
    qmlRegisterType<IpcManager>("HeadUnit", 1, 0, "IpcManager");
    qmlRegisterType<MockVehicleService>("HeadUnit", 1, 0, "MockVehicleService");

    // Create backend instances
    MediaManager mediaManager;
    IpcManager ipcManager;
    MockVehicleService mockVehicleService;
    
    // Setup QML engine
    QQmlApplicationEngine engine;
    
    // Expose backend instances to QML
    engine.rootContext()->setContextProperty("mediaManager", &mediaManager);
    engine.rootContext()->setContextProperty("ipcManager", &ipcManager);
    engine.rootContext()->setContextProperty("mockVehicleService", &mockVehicleService);
    
    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "Failed to load QML file:" << url;
                QCoreApplication::exit(-1);
            } else {
                qDebug() << "Head Unit application loaded successfully";
            }
        },
        Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}
