#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

// ═══════════════════════════════════════════════════════════════════
// TODO: vsomeip 통합 후 아래 include를 Proxy로 교체
// ═══════════════════════════════════════════════════════════════════
// #include "proxies/MediaProxy.h"
// #include "proxies/GearProxy.h"
// #include "proxies/AmbientProxy.h"

// 임시: 직접 Manager include (vsomeip 전까지)
#include "../../MediaApp/src/mediamanager.h"
#include "../../GearApp/src/gearmanager.h"
#include "../../AmbientApp/src/ambientmanager.h"
#include "../../GearApp/src/ipcmanager.h"

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════
    // Wayland Display Server 강제 설정
    // 별도 스크립트 없이 자동으로 Wayland 사용
    // ═══════════════════════════════════════════════════════
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    
    QGuiApplication app(argc, argv);
    app.setApplicationName("HeadUnit-MainApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "HU_MainApp (UI Integration) Starting...";
    qDebug() << "Display Server:" << app.platformName();
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // 현재 단계: 모든 Manager를 단일 프로세스에서 실행
    // 향후 vsomeip 통합 시: Proxy 객체로 교체
    // ═══════════════════════════════════════════════════════
    
    // Create backend instances
    MediaManager mediaManager;
    GearManager gearManager;
    AmbientManager ambientManager;
    IpcManager ipcManager;
    
    // ═══════════════════════════════════════════════════════
    // HU 내부 통신: Signal/Slot 연결
    // (향후 vsomeip로 전환 시 제거)
    // ═══════════════════════════════════════════════════════
    
    // IC → GearManager
    QObject::connect(&ipcManager, &IpcManager::gearStatusReceivedFromIC,
                     &gearManager, &GearManager::onGearStatusReceivedFromIC);
    
    // GearManager → AmbientManager
    QObject::connect(&gearManager, &GearManager::gearPositionChanged,
                     &ambientManager, &AmbientManager::onGearPositionChanged);
    
    // MediaManager → AmbientManager (TODO: volumeChanged signal)
    // QObject::connect(&mediaManager, &MediaManager::volumeChanged,
    //                  &ambientManager, &AmbientManager::onVolumeChanged);
    
    qDebug() << "✅ Backend managers initialized:";
    qDebug() << "   - MediaManager (USB media playback)";
    qDebug() << "   - GearManager (Gear control + IC sync)";
    qDebug() << "   - AmbientManager (Lighting control)";
    qDebug() << "   - IpcManager (IC communication)";
    qDebug() << "";
    qDebug() << "✅ Internal connections established:";
    qDebug() << "   - IpcManager → GearManager";
    qDebug() << "   - GearManager → AmbientManager (gear → color)";
    qDebug() << "   - MediaManager → AmbientManager (volume → brightness) [TODO]";
    qDebug() << "";
    qDebug() << "📌 NOTE: 현재는 단일 프로세스 모드로 실행됩니다.";
    qDebug() << "   파일 구조는 다중 프로세스 준비가 완료되었습니다.";
    qDebug() << "   향후 vsomeip 통합 시:";
    qDebug() << "   - MediaProxy로 MediaApp 접근";
    qDebug() << "   - GearProxy로 GearApp 접근";
    qDebug() << "   - AmbientProxy로 AmbientApp 접근";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // Setup QML engine
    // ═══════════════════════════════════════════════════════
    QQmlApplicationEngine engine;
    
    // Expose backend instances to QML
    engine.rootContext()->setContextProperty("mediaManager", &mediaManager);
    engine.rootContext()->setContextProperty("gearManager", &gearManager);
    engine.rootContext()->setContextProperty("ambientManager", &ambientManager);
    engine.rootContext()->setContextProperty("ipcManager", &ipcManager);
    
    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "Failed to load QML file:" << url;
                QCoreApplication::exit(-1);
            } else {
                qDebug() << "";
                qDebug() << "✅ Head Unit UI loaded successfully";
                qDebug() << "   QML components ready";
                qDebug() << "";
            }
        },
        Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}
