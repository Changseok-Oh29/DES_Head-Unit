#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include "gearmanager.h"
#include "ipcmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("GearApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "GearApp Process Starting...";
    qDebug() << "Service: GearManager (Gear Control + IC Communication)";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // GearManager + IpcManager 백엔드 로직 생성
    // ═══════════════════════════════════════════════════════
    GearManager gearManager;
    IpcManager ipcManager;  // IC 통신 담당
    
    // ═══════════════════════════════════════════════════════
    // IC → GearManager 연결
    // ═══════════════════════════════════════════════════════
    QObject::connect(&ipcManager, &IpcManager::gearStatusReceivedFromIC,
                     &gearManager, &GearManager::onGearStatusReceivedFromIC);
    
    qDebug() << "✅ Connection established: IpcManager → GearManager";
    
    // 디버그: Signal 연결 확인
    QObject::connect(&gearManager, &GearManager::gearPositionChanged,
                     [](const QString &gear){ 
                         qDebug() << "[GearApp] gearPositionChanged signal emitted:" << gear; 
                     });
    
    qDebug() << "";
    qDebug() << "✅ GearManager initialized";
    qDebug() << "   - Current Gear:" << gearManager.gearPosition();
    qDebug() << "";
    qDebug() << "✅ IpcManager initialized";
    qDebug() << "   - Listening on port: 12346";
    qDebug() << "   - IC Address: 127.0.0.1:12345";
    qDebug() << "";
    qDebug() << "📌 NOTE: 현재는 독립 프로세스로 실행됩니다.";
    qDebug() << "   향후 vsomeip 통합 시 다른 프로세스와 통신합니다.";
    qDebug() << "";
    qDebug() << "GearApp is running...";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // QML GUI 로드 (테스트/개발 모드)
    // ═══════════════════════════════════════════════════════
    QQmlApplicationEngine engine;
    
    // C++ 객체를 QML에 노출
    engine.rootContext()->setContextProperty("gearManager", &gearManager);
    engine.rootContext()->setContextProperty("ipcManager", &ipcManager);
    
    // QML 파일 로드
    const QUrl url(QStringLiteral("qrc:/qml/GearSelectionWidget.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "❌ Failed to load QML file!";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);
    
    if (!engine.rootObjects().isEmpty()) {
        qDebug() << "✅ QML GUI loaded: GearSelectionWidget.qml";
        qDebug() << "🖥️  Window should appear now!";
    }
    
    qDebug() << "";
    
    // ═══════════════════════════════════════════════════════
    // 테스트: 10초마다 기어 변경 시뮬레이션
    // ═══════════════════════════════════════════════════════
    QTimer *testTimer = new QTimer(&app);
    QStringList gears = {"P", "R", "N", "D"};
    int gearIndex = 0;
    QObject::connect(testTimer, &QTimer::timeout, [&gearManager, &gears, &gearIndex]() {
        gearIndex = (gearIndex + 1) % gears.size();
        QString nextGear = gears[gearIndex];
        qDebug() << "";
        qDebug() << "🧪 [Test] Setting gear to:" << nextGear;
        gearManager.setGearPosition(nextGear);
    });
    // testTimer->start(10000);  // 테스트용 타이머 (필요시 주석 해제)
    
    return app.exec();
}
