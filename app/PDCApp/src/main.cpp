#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include "VehicleControlClient.h"

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════════
    // Environment variables - use deployment paths if not already set
    // ═══════════════════════════════════════════════════════════
    // vsomeip app name
    if (qgetenv("VSOMEIP_APPLICATION_NAME").isEmpty()) {
        qputenv("VSOMEIP_APPLICATION_NAME", "PDCApp");
    }

    // vsomeip config - check if already set by environment, otherwise use default
    if (qgetenv("VSOMEIP_CONFIGURATION").isEmpty()) {
        qputenv("VSOMEIP_CONFIGURATION", "/home/seame/PDC/headunit/DES_Head-Unit/app/PDCApp/config/vsomeip_pdc.json");
    }

    // commonapi config - check if already set by environment, otherwise use default
    if (qgetenv("COMMONAPI_CONFIG").isEmpty()) {
        qputenv("COMMONAPI_CONFIG", "/home/seame/PDC/headunit/DES_Head-Unit/commonapi/commonapi.ini");
    }

    // Wayland settings - only set if not already configured
    if (qgetenv("XDG_RUNTIME_DIR").isEmpty()) {
        qputenv("XDG_RUNTIME_DIR", "/run/user/0");
    }
    if (qgetenv("QT_QPA_PLATFORM").isEmpty()) {
        qputenv("QT_QPA_PLATFORM", "wayland");
    }
    if (qgetenv("QT_WAYLAND_DISABLE_WINDOWDECORATION").isEmpty()) {
        qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    }
    if (qgetenv("WAYLAND_DISPLAY").isEmpty()) {
        qputenv("WAYLAND_DISPLAY", "wayland-1");
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName("PDCApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "PDCApp Process Starting...";
    qDebug() << "Service: Park Distance Control Visualization";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Environment Configuration:";
    qDebug() << "   VSOMEIP_CONFIGURATION:" << qgetenv("VSOMEIP_CONFIGURATION");
    qDebug() << "   COMMONAPI_CONFIG:" << qgetenv("COMMONAPI_CONFIG");
    qDebug() << "   QT_QPA_PLATFORM:" << qgetenv("QT_QPA_PLATFORM");
    qDebug() << "   WAYLAND_DISPLAY:" << qgetenv("WAYLAND_DISPLAY");
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════════
    // VehicleControlClient (vsomeip) creation and initialization
    // ═══════════════════════════════════════════════════════════
    VehicleControlClient vehicleControlClient;
    vehicleControlClient.initialize();

    qDebug() << "";
    qDebug() << "VehicleControlClient initialized";
    qDebug() << "   - Service Available:" << vehicleControlClient.serviceAvailable();
    qDebug() << "   - Current Gear:" << vehicleControlClient.currentGear();
    qDebug() << "   - Current Distance:" << vehicleControlClient.currentDistance() << "cm";
    qDebug() << "";

    // ═══════════════════════════════════════════════════════════
    // QML GUI Load
    // ═══════════════════════════════════════════════════════════
    QQmlApplicationEngine engine;

    // Expose C++ objects to QML
    engine.rootContext()->setContextProperty("vehicleControlClient", &vehicleControlClient);

    // Load QML file
    const QUrl url(QStringLiteral("qrc:/qml/PDCDisplay.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML file!";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    if (!engine.rootObjects().isEmpty()) {
        qDebug() << "QML GUI loaded: PDCDisplay.qml";
    }

    qDebug() << "";
    qDebug() << "PDCApp is running...";
    qDebug() << "═══════════════════════════════════════════════════════";

    return app.exec();
}
