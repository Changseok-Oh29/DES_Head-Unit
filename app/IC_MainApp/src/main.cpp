#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

int main(int argc, char *argv[])
{
    // Set platform to Wayland only if not already specified (allows xcb for local testing)
    if (qgetenv("QT_QPA_PLATFORM").isEmpty()) {
        qputenv("QT_QPA_PLATFORM", "wayland");
    }

    // Wayland-specific settings (only apply if using wayland)
    if (qgetenv("QT_QPA_PLATFORM") == "wayland") {
        // Disable window decorations
        qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

        // Ensure XDG shell is used
        qputenv("QT_WAYLAND_SHELL_INTEGRATION", "xdg-shell");
    }

    // Create XDG_RUNTIME_DIR if not set
    if (qgetenv("XDG_RUNTIME_DIR").isEmpty()) {
        qputenv("XDG_RUNTIME_DIR", "/run/user/1000");
    }

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    // KIOSK SHELL: Set application name for display routing
    // This name must match the app-ids in weston.ini
    app.setApplicationName("InstrumentClusterApp");  // Routes to DSI-1 output
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    app.setDesktopFileName("InstrumentClusterApp");  // Critical for Wayland app_id

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "IC_MainApp - Nested Wayland Compositor (Kiosk Shell)";
    qDebug() << "App ID: InstrumentClusterApp → DSI-1 (400x1280 portrait)";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Display Platform:" << app.platformName();
    qDebug() << "Parent Compositor:" << qgetenv("WAYLAND_DISPLAY");
    qDebug() << "";
    qDebug() << "Role: Nested Wayland Compositor";
    qDebug() << "   - Client of Weston (wayland-0)";
    qDebug() << "   - Shows on DSI via Kiosk Shell routing";
    qDebug() << "   - Creates wayland-2 socket for IC apps";
    qDebug() << "   - Manages SpeedApp, BatteryApp, ICGearApp";
    qDebug() << "═══════════════════════════════════════════════════════";

    // QML Engine - Compositor UI
    QQmlApplicationEngine engine;

    // Add QML import path for Qt modules
    engine.addImportPath("/usr/lib/qml");

    // Load compositor QML
    const QUrl url(QStringLiteral("qrc:/qml/ic_compositor.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "Failed to load IC Compositor QML:" << url;
                QCoreApplication::exit(-1);
            } else {
                qDebug() << "";
                qDebug() << "IC Compositor UI loaded";
                qDebug() << "   Ready to embed IC app windows";
                qDebug() << "";
            }
        },
        Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects found!";
        return -1;
    }

    qDebug() << "IC Compositor running...";
    qDebug() << "   Waiting for IC apps to connect...";
    qDebug() << "";

    return app.exec();
}
