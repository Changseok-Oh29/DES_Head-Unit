#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include <CommonAPI/CommonAPI.hpp>
#include "mediamanager.h"
#include "MediaControlStubImpl.h"

int main(int argc, char *argv[])
{
    // Set vsomeip application name BEFORE creating QApplication
    qputenv("VSOMEIP_APPLICATION_NAME", "MediaApp");

    QGuiApplication app(argc, argv);
    app.setApplicationName("MediaApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "MediaApp (vsomeip Service) Starting...";
    qDebug() << "Service: MediaControl (USB Media Playback + Volume Events)";
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════
    // MediaManager backend logic
    // ═══════════════════════════════════════════════════════
    MediaManager mediaManager;

    qDebug() << "";
    qDebug() << "✅ MediaManager initialized";
    qDebug() << "   - Volume:" << mediaManager.volume();
    qDebug() << "   - isPlaying:" << mediaManager.isPlaying();

    // ═══════════════════════════════════════════════════════
    // CommonAPI vsomeip Service Registration
    // ═══════════════════════════════════════════════════════
    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::shared_ptr<v1::mediacontrol::MediaControlStubImpl> mediaService =
        std::make_shared<v1::mediacontrol::MediaControlStubImpl>(&mediaManager);

    const std::string domain = "local";
    const std::string instance = "mediacontrol.MediaControl";

    bool success = runtime->registerService(domain, instance, mediaService);

    if (success) {
        qDebug() << "✅ MediaControl vsomeip service registered successfully";
        qDebug() << "   Domain:" << QString::fromStdString(domain);
        qDebug() << "   Instance:" << QString::fromStdString(instance);
    } else {
        qCritical() << "❌ Failed to register MediaControl service!";
        return -1;
    }

    qDebug() << "";
    qDebug() << "📡 vsomeip Service Status:";
    qDebug() << "   - Service: MediaControl";
    qDebug() << "   - Events: volumeChanged";
    qDebug() << "   - Methods: getVolume()";
    qDebug() << "   - Clients: AmbientApp can subscribe";
    qDebug() << "";
    qDebug() << "MediaApp is running as vsomeip service...";
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════
    // QML GUI (Optional - for standalone testing with UI)
    // ═══════════════════════════════════════════════════════
    QQmlApplicationEngine engine;

    // Expose C++ objects to QML
    engine.rootContext()->setContextProperty("mediaManager", &mediaManager);

    // Load QML file
    const QUrl url(QStringLiteral("qrc:/qml/MediaApp.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "❌ Failed to load QML file:" << url;
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    if (!engine.rootObjects().isEmpty()) {
        qDebug() << "✅ QML GUI loaded: MediaApp.qml";
        qDebug() << "🖥️  Window should appear now!";
    }

    qDebug() << "";

    // ═══════════════════════════════════════════════════════
    // Test Timer: Simulate volume changes every 5 seconds
    // ═══════════════════════════════════════════════════════
    QTimer *testTimer = new QTimer(&app);
    QObject::connect(testTimer, &QTimer::timeout, [&mediaManager]() {
        static qreal testVolume = 0.8;
        testVolume = (testVolume >= 1.0) ? 0.0 : (testVolume + 0.2);
        qDebug() << "";
        qDebug() << "🧪 [Test] Simulating volume change to:" << testVolume;
        mediaManager.setVolume(testVolume);
    });
    testTimer->start(5000);  // Change volume every 5 seconds
    qDebug() << "🧪 Test timer enabled: Volume will change every 5 seconds";

    return app.exec();
}
