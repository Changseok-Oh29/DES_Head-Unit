#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include "VehicleControlClient.h"

int main(int argc, char *argv[])
{
    // Environment variables - use deployment paths if not already set
    if (qgetenv("VSOMEIP_APPLICATION_NAME").isEmpty()) {
        qputenv("VSOMEIP_APPLICATION_NAME", "SpeedApp");
    }

    if (qgetenv("VSOMEIP_CONFIGURATION").isEmpty()) {
        qputenv("VSOMEIP_CONFIGURATION", "/etc/vsomeip/vsomeip_speed.json");
    }

    if (qgetenv("COMMONAPI_CONFIG").isEmpty()) {
        qputenv("COMMONAPI_CONFIG", "/etc/commonapi/commonapi.ini");
    }

    // Wayland settings - connect to IC_MainApp compositor (wayland-2)
    // Each variable set independently (like GearApp does)
    if (qgetenv("XDG_RUNTIME_DIR").isEmpty()) {
        qputenv("XDG_RUNTIME_DIR", "/run/user/1000");
    }
    if (qgetenv("QT_QPA_PLATFORM").isEmpty()) {
        qputenv("QT_QPA_PLATFORM", "wayland");
    }
    if (qgetenv("QT_WAYLAND_DISABLE_WINDOWDECORATION").isEmpty()) {
        qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    }
    if (qgetenv("WAYLAND_DISPLAY").isEmpty()) {
        qputenv("WAYLAND_DISPLAY", "wayland-2");  // Connect to IC_MainApp
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName("SpeedApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "SpeedApp Process Starting...";
    qDebug() << "Service: Speedometer Display (vsomeip Client)";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Environment Configuration:";
    qDebug() << "   VSOMEIP_CONFIGURATION:" << qgetenv("VSOMEIP_CONFIGURATION");
    qDebug() << "   COMMONAPI_CONFIG:" << qgetenv("COMMONAPI_CONFIG");
    qDebug() << "   QT_QPA_PLATFORM:" << qgetenv("QT_QPA_PLATFORM");
    qDebug() << "   WAYLAND_DISPLAY:" << qgetenv("WAYLAND_DISPLAY");
    qDebug() << "═══════════════════════════════════════════════════════";

    // VehicleControlClient (vsomeip) creation and connection
    VehicleControlClient vehicleControlClient;
    vehicleControlClient.initialize();

    qDebug() << "";
    qDebug() << "VehicleControlClient initialized";
    qDebug() << "   - Service: VehicleControl @ ECU1";
    qDebug() << "";

    // QML GUI Load
    QQmlApplicationEngine engine;

    // Expose C++ objects to QML
    engine.rootContext()->setContextProperty("vehicleClient", &vehicleControlClient);

    // Load QML file
    const QUrl url(QStringLiteral("qrc:/qml/SpeedWidget.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML file!";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    if (!engine.rootObjects().isEmpty()) {
        qDebug() << "QML GUI loaded: SpeedWidget.qml";
    }

    qDebug() << "";
    qDebug() << "SpeedApp is running...";
    qDebug() << "═══════════════════════════════════════════════════════";

    return app.exec();
}
