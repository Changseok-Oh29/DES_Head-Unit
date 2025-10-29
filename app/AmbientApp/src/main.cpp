#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include <CommonAPI/CommonAPI.hpp>
#include "ambientmanager.h"
#include "MediaControlClient.h"

int main(int argc, char *argv[])
{
    // Set vsomeip application name BEFORE creating QApplication
    qputenv("VSOMEIP_APPLICATION_NAME", "AmbientApp");

    QGuiApplication app(argc, argv);
    app.setApplicationName("AmbientApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");

    qDebug() << "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP";
    qDebug() << "AmbientApp Process Starting...";
    qDebug() << "Service: AmbientManager (Ambient Lighting Control)";
    qDebug() << "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP";

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // AmbientManager 1�� \� �1
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    AmbientManager ambientManager;

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // vSOMEIP 클라이언트 초기화
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    qDebug() << "";
    qDebug() << "🔧 Initializing vSOMEIP Client...";
    
    MediaControlClient* mediaControlClient = new MediaControlClient(&ambientManager, &app);
    
    if (!mediaControlClient->initialize()) {
        qCritical() << "❌ Failed to initialize MediaControl client!";
        return -1;
    }
    
    qDebug() << "✅ MediaControl client initialized";
    qDebug() << "   Waiting for MediaApp service...";

    // ��: Signal � Ux
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
    qDebug() << " AmbientManager initialized";
    qDebug() << "   - Current Color:" << ambientManager.ambientColor();
    qDebug() << "   - Brightness:" << ambientManager.brightness();
    qDebug() << "";
    qDebug() << "=� NOTE: �� Ž \8�\ �)��.";
    qDebug() << "   �� vsomeip �i � �x \8�@ ��i��.";
    qDebug() << "   GearApp<\�0 0� �� �8| D ��D �� ��i��.";
    qDebug() << "";
    qDebug() << "AmbientApp is running...";
    qDebug() << "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP";

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // QML GUI \� (L��/ ��)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    QQmlApplicationEngine engine;

    // C++ �| QML� x�
    engine.rootContext()->setContextProperty("ambientManager", &ambientManager);

    // QML | \�
    const QUrl url(QStringLiteral("qrc:/qml/AmbientLighting.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "L Failed to load QML file!";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    if (!engine.rootObjects().isEmpty()) {
        qDebug() << " QML GUI loaded: AmbientLighting.qml";
        qDebug() << "=�  Window should appear now!";
    }

    qDebug() << "";

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // L��: 5�� �� �� ܬtX (0� �� ܬtX)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    QTimer *testTimer = new QTimer(&app);
    QStringList testGears = {"P", "R", "N", "D"};
    int gearIndex = 0;
    QObject::connect(testTimer, &QTimer::timeout, [&ambientManager, &testGears, &gearIndex]() {
        QString testGear = testGears[gearIndex];
        gearIndex = (gearIndex + 1) % testGears.size();
        qDebug() << "";
        qDebug() << ">� [Test] Simulating gear change to:" << testGear;
        ambientManager.onGearPositionChanged(testGear);
    });
    // testTimer->start(5000);  // L��� �t8 (D�� � t)

    return app.exec();
}
