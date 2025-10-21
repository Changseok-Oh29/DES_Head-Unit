#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include "mediamanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("MediaApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "MediaApp Process Starting...";
    qDebug() << "Service: MediaManager (USB Media Playback)";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // MediaManager 백엔드 로직 생성
    // ═══════════════════════════════════════════════════════
    MediaManager mediaManager;
    
    // 디버그: Signal 연결 확인
    QObject::connect(&mediaManager, &MediaManager::volumeChanged,
                     [](){ 
                         qDebug() << "[MediaApp] volumeChanged signal emitted"; 
                     });
    
    QObject::connect(&mediaManager, &MediaManager::playbackStateChanged,
                     [](){ 
                         qDebug() << "[MediaApp] playbackStateChanged signal emitted"; 
                     });
    
    qDebug() << "";
    qDebug() << "✅ MediaManager initialized";
    qDebug() << "   - Volume:" << mediaManager.volume();
    qDebug() << "   - isPlaying:" << mediaManager.isPlaying();
    qDebug() << "";
    qDebug() << "📌 NOTE: 현재는 독립 프로세스로 실행됩니다.";
    qDebug() << "   향후 vsomeip 통합 시 다른 프로세스와 통신합니다.";
    qDebug() << "";
    qDebug() << "MediaApp is running...";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // QML GUI 로드 (테스트/개발 모드)
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
    // 테스트: 5초마다 볼륨 변경 시뮬레이션
    // ═══════════════════════════════════════════════════════
    QTimer *testTimer = new QTimer(&app);
    int testVolume = 50;
    QObject::connect(testTimer, &QTimer::timeout, [&mediaManager, &testVolume]() {
        testVolume = (testVolume + 10) % 100;
        qDebug() << "";
        qDebug() << "🧪 [Test] Setting volume to:" << testVolume;
        mediaManager.setVolume(testVolume);
    });
    // testTimer->start(5000);  // 테스트용 타이머 (필요시 주석 해제)
    
    return app.exec();
}
