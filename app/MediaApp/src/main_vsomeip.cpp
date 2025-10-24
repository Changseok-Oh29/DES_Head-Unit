#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include <thread>

#include <CommonAPI/CommonAPI.hpp>
#include "mediamanager.h"
#include "MediaControlStubImpl.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("MediaApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "MediaApp (vsomeip Service) Starting...";
    qDebug() << "Service: MediaControl (USB Media Playback + Volume Events)";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // MediaManager 백엔드 로직 생성 (기존 로직 활용)
    // ═══════════════════════════════════════════════════════
    MediaManager mediaManager;
    
    qDebug() << "✅ MediaManager initialized";
    qDebug() << "   - Volume:" << mediaManager.volume();
    qDebug() << "   - isPlaying:" << mediaManager.isPlaying();
    
    // ═══════════════════════════════════════════════════════
    // CommonAPI vsomeip Service 등록
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
    
    // ═══════════════════════════════════════════════════════
    // QML GUI 로드 (선택사항 - 독립 테스트용)
    // ═══════════════════════════════════════════════════════
    QQmlApplicationEngine engine;
    
    // C++ 객체를 QML에 노출
    engine.rootContext()->setContextProperty("mediaManager", &mediaManager);
    
    // QML 파일 로드
    const QUrl url(QStringLiteral("qrc:/MediaApp.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "❌ Failed to load QML file!";
        }
    }, Qt::QueuedConnection);
    engine.load(url);
    
    if (!engine.rootObjects().isEmpty()) {
        qDebug() << "✅ QML GUI loaded: MediaApp.qml";
    }
    
    qDebug() << "MediaApp is running as vsomeip service...";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    return app.exec();
}
