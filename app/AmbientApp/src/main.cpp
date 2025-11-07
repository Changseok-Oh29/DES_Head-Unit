#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include <CommonAPI/CommonAPI.hpp>
#include "ambientmanager.h"
#include "MediaControlClient.h"
#include "VehicleControlClient.h"

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════
    // CRITICAL: Set environment BEFORE QGuiApplication
    // ═══════════════════════════════════════════════════════
    qputenv("VSOMEIP_APPLICATION_NAME", "AmbientApp");
    qputenv("QT_QUICK_BACKEND", "software");
    qputenv("LIBGL_ALWAYS_SOFTWARE", "1");
    qputenv("QT_OPENGL", "software");
    
    // Set application metadata BEFORE creating QGuiApplication
    QCoreApplication::setApplicationName("AmbientApp");
    QCoreApplication::setApplicationVersion("1.0");
    QCoreApplication::setOrganizationName("SEA-ME");

    QGuiApplication app(argc, argv);
    app.setDesktopFileName("AmbientApp");  // For Wayland appId

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "AmbientApp Process Starting...";
    qDebug() << "Service: AmbientManager (Ambient Lighting Control)";
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════════
    // AmbientManager 생성
    // ═══════════════════════════════════════════════════════════
    AmbientManager ambientManager;

    // ═══════════════════════════════════════════════════════════
    // vSOMEIP 클라이언트 초기화
    // ═══════════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "🔧 Initializing vSOMEIP Clients...";
    
    // MediaControl Client (볼륨 → 밝기)
    MediaControlClient* mediaControlClient = new MediaControlClient(&ambientManager, &app);
    
    if (!mediaControlClient->initialize()) {
        qCritical() << "❌ Failed to initialize MediaControl client!";
        return -1;
    }
    
    qDebug() << "✅ MediaControl client initialized";
    qDebug() << "   Waiting for MediaApp service...";
    
    // VehicleControl Client (기어 → 색상)
    VehicleControlClient* vehicleControlClient = new VehicleControlClient(&app);
    
    if (!vehicleControlClient->initialize()) {
        qCritical() << "❌ Failed to initialize VehicleControl client!";
        return -1;
    }
    
    qDebug() << "✅ VehicleControl client initialized";
    qDebug() << "   Waiting for VehicleControlECU service...";
    
    // Connect VehicleControl gear changes to AmbientManager
    QObject::connect(vehicleControlClient, &VehicleControlClient::currentGearChanged,
                     &ambientManager, &AmbientManager::onGearPositionChanged);
    
    qDebug() << "✅ VehicleControl → AmbientManager connection established";
    qDebug() << "   (Gear changes will update ambient light color)";
    qDebug() << "";

    // Debug: Signal 테스트
    QObject::connect(&ambientManager, &AmbientManager::ambientColorChanged,
                     [&ambientManager](){
                         qDebug() << "[AmbientApp] ambientColorChanged signal emitted:"
                                  << ambientManager.ambientColor();
                     });

    QObject::connect(&ambientManager, &AmbientManager::brightnessChanged,
                     [&ambientManager](){
                         qDebug() << "[AmbientApp] brightnessChanged signal emitted:"
                                  << ambientManager.brightness();
                     });

    qDebug() << "";
    qDebug() << "✅ AmbientManager initialized";
    qDebug() << "   - Current Color:" << ambientManager.ambientColor();
    qDebug() << "   - Brightness:" << ambientManager.brightness();
    qDebug() << "";
    qDebug() << "📋 Communication Setup:";
    qDebug() << "   - MediaApp → AmbientApp (Volume → Brightness)";
    qDebug() << "   - VehicleControlECU → AmbientApp (Gear → Color)";
    qDebug() << "";
    qDebug() << "AmbientApp is running...";
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════════
    // QML GUI 로드
    // ═══════════════════════════════════════════════════════════
    QQmlApplicationEngine engine;

    // C++ 객체를 QML에 노출
    engine.rootContext()->setContextProperty("ambientManager", &ambientManager);

    // QML 파일 로드
    const QUrl url(QStringLiteral("qrc:/qml/AmbientLighting.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "❌ Failed to load QML file!";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    if (!engine.rootObjects().isEmpty()) {
        qDebug() << "✅ QML GUI loaded: AmbientLighting.qml";
        
        // Wayland용 Window title 명시적 설정
        QObject *rootObject = engine.rootObjects().first();
        if (rootObject) {
            rootObject->setProperty("title", "Ambient");
            qDebug() << "   Window title set to: Ambient";
        }
        
        qDebug() << "   Window should appear now!";
    }

    qDebug() << "";

    return app.exec();
}
