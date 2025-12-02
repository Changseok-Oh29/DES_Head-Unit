#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════
    // HU_MainApp - Wayland Compositor (EGLFS mode)
    // ═══════════════════════════════════════════════════════
    // IMPORTANT: HU_MainApp runs as a Wayland compositor using EGLFS backend
    // - Direct hardware access via EGLFS
    // - Provides compositor for other Wayland clients
    // - Manages window layout and surface routing

    // Set platform to EGLFS
    qputenv("QT_QPA_PLATFORM", "eglfs");

    // Disable window decorations
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // Create XDG_RUNTIME_DIR if not set
    if (qgetenv("XDG_RUNTIME_DIR").isEmpty()) {
        qputenv("XDG_RUNTIME_DIR", "/run/user/0");
    }

    // Set wayland socket name for this compositor
    if (qgetenv("WAYLAND_DISPLAY").isEmpty()) {
        qputenv("WAYLAND_DISPLAY", "wayland-1");
    }

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName("HeadUnit-Compositor");
    app.setApplicationVersion("2.0-EGLFS");
    app.setOrganizationName("SEA-ME");

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "HU_MainApp - Wayland Compositor (EGLFS mode)";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Display Platform:" << app.platformName();
    qDebug() << "Wayland Display:" << qgetenv("WAYLAND_DISPLAY");
    qDebug() << "";
    qDebug() << "📋 Role: Wayland Compositor";
    qDebug() << "   - Provides compositor surface";
    qDebug() << "   - Manages app window embedding";
    qDebug() << "   - Direct EGLFS hardware access";
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════
    // QML Engine - Compositor UI
    // ═══════════════════════════════════════════════════════
    QQmlApplicationEngine engine;

    // Add QML import path for Qt modules
    engine.addImportPath("/usr/lib/qml");

    // Load compositor QML
    const QUrl url(QStringLiteral("qrc:/qml/compositor_modular.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "❌ Failed to load Compositor QML:" << url;
                QCoreApplication::exit(-1);
            } else {
                qDebug() << "";
                qDebug() << "✅ Compositor UI loaded";
                qDebug() << "   Ready to embed app windows";
                qDebug() << "";
            }
        },
        Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "❌ No root objects found!";
        return -1;
    }

    qDebug() << "🚀 Compositor running...";
    qDebug() << "   Waiting for HU apps to connect...";
    qDebug() << "";

    return app.exec();
}
