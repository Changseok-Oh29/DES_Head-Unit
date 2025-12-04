#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>
#include <QTimer>
#include <QWindow>
#include "caninterface.h"
#include "vehiclecontrolclient.h"

int main(int argc, char *argv[])
{
    // Set app_id BEFORE creating QGuiApplication
    // This ensures Qt Wayland uses it from the start
    qputenv("QT_WAYLAND_SHELL_INTEGRATION", "xdg-shell");

    QGuiApplication app(argc, argv);

    // ═══════════════════════════════════════════════════════
    // KIOSK SHELL: Set application name for display routing
    // ═══════════════════════════════════════════════════════
    // This name must match the app-ids in weston.ini
    app.setApplicationName("appIC");  // ← Routes to HDMI-A-2 output
    app.setApplicationDisplayName("Instrument Cluster");
    app.setDesktopFileName("appIC");  // Critical for Wayland app_id

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "IC_app Starting (Kiosk Shell - DSI Display)";
    qDebug() << "App ID: appIC → DSI-1 (400x1280)";
    qDebug() << "═══════════════════════════════════════════════════════";
    
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

    // ═══════════════════════════════════════════════════════
    // Register C++ objects to QML context
    // ═══════════════════════════════════════════════════════
    
    // CAN Interface (Arduino Speed/RPM)
    CanInterface canInterface;
    engine.rootContext()->setContextProperty("canInterface", &canInterface);

    // VehicleControlClient (vsomeip - Gear/Battery)
    VehicleControlClient vehicleClient;
    engine.rootContext()->setContextProperty("vehicleClient", &vehicleClient);
    
    qDebug() << "";
    qDebug() << "✅ C++ backends created:";
    qDebug() << "   - CanInterface (CAN Bus)";
    qDebug() << "   - VehicleControlClient (vsomeip)";
    qDebug() << "";
    
    // Initialize vsomeip connection
    vehicleClient.initialize();

    const QUrl url(QStringLiteral("qrc:/DesignContent/App.qml"));

    // Handle QML loading failure
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (url == objUrl) {
                             if (!obj) {
                                 qCritical() << "❌ Failed to load QML!";
                                 QCoreApplication::exit(-1);
                             }
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    // Check if QML root objects were created
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "❌ QML root objects are empty!";
        return -1;
    }
    
    qDebug() << "✅ QML UI loaded";

    // Connect to CAN interface
    qDebug() << "";
    qDebug() << "🔌 Connecting to CAN interface...";
    if (canInterface.connectToCan("can0")) {
        canInterface.startReceiving();
        qDebug() << "✅ CAN interface connected (can0)";
    } else {
        qWarning() << "⚠️  CAN interface not available (can0)";
    }
    
    qDebug() << "";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "🚀 IC_app is now running!";
    qDebug() << "   - CAN: Arduino Speed/RPM";
    qDebug() << "   - vsomeip: VehicleControlECU (Raspberry Pi)";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "";

    return app.exec();
}
