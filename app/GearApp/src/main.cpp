#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include <QWindow>
#include <QQuickWindow>
#include "gearmanager.h"
#include "VehicleControlClient.h"

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════════
    // Environment variables - use deployment paths if not already set
    // ═══════════════════════════════════════════════════════════
    // vsomeip app name
    if (qgetenv("VSOMEIP_APPLICATION_NAME").isEmpty()) {
        qputenv("VSOMEIP_APPLICATION_NAME", "GearApp");
    }

    // vsomeip config - check if already set by environment, otherwise use default
    if (qgetenv("VSOMEIP_CONFIGURATION").isEmpty()) {
        qputenv("VSOMEIP_CONFIGURATION", "/etc/vsomeip/vsomeip_gear.json");
    }

    // commonapi config - check if already set by environment, otherwise use default
    if (qgetenv("COMMONAPI_CONFIG").isEmpty()) {
        qputenv("COMMONAPI_CONFIG", "/etc/commonapi/commonapi.ini");
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
    app.setApplicationName("GearApp");
    app.setApplicationDisplayName("GearApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    
    // Wayland App ID 설정 (Compositor가 앱을 식별하는데 사용)
    app.setDesktopFileName("GearApp.desktop");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "GearApp Process Starting...";
    qDebug() << "Service: GearManager (Gear Control + vsomeip Client)";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "📋 Environment Configuration:";
    qDebug() << "   VSOMEIP_CONFIGURATION:" << qgetenv("VSOMEIP_CONFIGURATION");
    qDebug() << "   COMMONAPI_CONFIG:" << qgetenv("COMMONAPI_CONFIG");
    qDebug() << "   QT_QPA_PLATFORM:" << qgetenv("QT_QPA_PLATFORM");
    qDebug() << "   WAYLAND_DISPLAY:" << qgetenv("WAYLAND_DISPLAY");
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════════
    // VehicleControlClient (vsomeip) 생성 및 연결
    // ═══════════════════════════════════════════════════════════
    VehicleControlClient vehicleControlClient;
    vehicleControlClient.connectToService();
    
    // ═══════════════════════════════════════════════════════════
    // GearManager 백엔드 로직 생성
    // ═══════════════════════════════════════════════════════════
    GearManager gearManager;
    
    // ═══════════════════════════════════════════════════════════
    // VehicleControlClient → GearManager 연결 (vsomeip 이벤트 수신)
    // ═══════════════════════════════════════════════════════════
    // FIX: Use updateGearFromService() instead of setProperty() to prevent feedback loop
    QObject::connect(&vehicleControlClient, &VehicleControlClient::currentGearChanged,
                     [&gearManager](const QString& gear) {
                         qDebug() << "[vsomeip → GearManager] Gear update:" << gear;
                         // Call updateGearFromService() which updates state WITHOUT triggering RPC
                         gearManager.updateGearFromService(gear);           // FIX: Breaks feedback loop
                     });
    
    qDebug() << "✅ Connection established: VehicleControlClient → GearManager";
    
    // ═══════════════════════════════════════════════════════════
    // GearManager → VehicleControlClient 연결 (QML에서 기어 변경 요청 시)
    // ═══════════════════════════════════════════════════════════
    QObject::connect(&gearManager, &GearManager::gearChangeRequested,
                     [&vehicleControlClient](const QString& gear) {
                         qDebug() << "[GearManager → vsomeip] Requesting gear change:" << gear;
                         vehicleControlClient.requestGearChange(gear);      // Send RPC to VehicleControlMock
                     });
    
    qDebug() << "✅ Connection established: GearManager → VehicleControlClient";
    
    // 디버그: Signal 연결 확인
    QObject::connect(&gearManager, &GearManager::gearPositionChanged,
                     [](const QString &gear){ 
                         qDebug() << "[GearApp] gearPositionChanged signal emitted:" << gear; 
                     });
    
    qDebug() << "";
    qDebug() << "✅ GearManager initialized";
    qDebug() << "   - Current Gear:" << gearManager.gearPosition();
    qDebug() << "";
    qDebug() << "✅ VehicleControlClient initialized";
    qDebug() << "   - Connected:" << vehicleControlClient.connected();
    qDebug() << "   - Service: VehicleControl @ ECU1 (192.168.1.100)";
    qDebug() << "";
    qDebug() << "📌 NOTE: vsomeip 통합 완료 - VehicleControlECU와 통신합니다";
    qDebug() << "";
    qDebug() << "GearApp is running...";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════════
    // QML GUI 로드 (테스트/개발 모드)
    // ═══════════════════════════════════════════════════════════
    QQmlApplicationEngine engine;
    
    // C++ 객체를 QML에 노출
    engine.rootContext()->setContextProperty("gearManager", &gearManager);
    engine.rootContext()->setContextProperty("vehicleControlClient", &vehicleControlClient);
    
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
        
        // Set Wayland app_id for the window
        QObject *rootObject = engine.rootObjects().first();
        if (rootObject) {
            QQuickWindow *window = qobject_cast<QQuickWindow*>(rootObject);
            if (window) {
                window->setProperty("_q_waylandAppId", "GearApp");
                qDebug() << "✅ Wayland App ID set: GearApp";
            } else {
                qWarning() << "⚠️  Failed to cast to QQuickWindow";
            }
        }
    }
    
    qDebug() << "";
    
    // ═══════════════════════════════════════════════════════════
    // 테스트: 10초마다 기어 변경 시뮬레이션
    // ═══════════════════════════════════════════════════════════
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
