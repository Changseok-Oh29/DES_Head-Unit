#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include "ambientmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("AmbientApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");

    qDebug() << "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP";
    qDebug() << "AmbientApp Process Starting...";
    qDebug() << "Service: AmbientManager (Ambient Lighting Control)";
    qDebug() << "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP";

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // AmbientManager 1ÔÜ \Á Ý1
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    AmbientManager ambientManager;

    // „ø: Signal ð° Ux
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
    qDebug() << "=Ì NOTE: ¬” Å½ \8¤\ ä‰)Èä.";
    qDebug() << "   ¥Ä vsomeip µi Ü äx \8¤@ µàiÈä.";
    qDebug() << "   GearApp<\€0 0´ À½ à8| D ÉÁD Ù À½iÈä.";
    qDebug() << "";
    qDebug() << "AmbientApp is running...";
    qDebug() << "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP";

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // QML GUI \Ü (L¤¸/ ¨Ü)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    QQmlApplicationEngine engine;

    // C++ ´| QMLÐ xœ
    engine.rootContext()->setContextProperty("ambientManager", &ambientManager);

    // QML | \Ü
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
        qDebug() << "=¥  Window should appear now!";
    }

    qDebug() << "";

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // L¤¸: 5Èä ÉÁ À½ Ü¬tX (0´ À½ Ü¬tX)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    QTimer *testTimer = new QTimer(&app);
    QStringList testGears = {"P", "R", "N", "D"};
    int gearIndex = 0;
    QObject::connect(testTimer, &QTimer::timeout, [&ambientManager, &testGears, &gearIndex]() {
        QString testGear = testGears[gearIndex];
        gearIndex = (gearIndex + 1) % testGears.size();
        qDebug() << "";
        qDebug() << ">ê [Test] Simulating gear change to:" << testGear;
        ambientManager.onGearPositionChanged(testGear);
    });
    // testTimer->start(5000);  // L¤¸© Àt8 (D”Ü ü t)

    return app.exec();
}
