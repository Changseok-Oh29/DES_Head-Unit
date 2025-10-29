#include <QCoreApplication>
#include <QTimer>
#include <QDebug>
#include <pigpio.h>
#include <csignal>

#include "PiRacerController.h"
#include "GamepadHandler.h"

// Global pointer for cleanup
PiRacerController* g_piracerController = nullptr;

void signalHandler(int signal)
{
    qDebug() << "";
    qDebug() << "🛑 Received signal" << signal << "- Shutting down...";
    
    if (g_piracerController) {
        g_piracerController->setThrottlePercent(0.0f);
        g_piracerController->setSteeringPercent(0.0f);
    }
    
    gpioTerminate();
    QCoreApplication::quit();
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName("VehicleControlECU_Standalone");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "VehicleControlECU - Standalone Mode";
    qDebug() << "Hardware Control Only (No vsomeip)";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // Signal handler for safe shutdown
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    // ═══════════════════════════════════════════════════════
    // 1. Initialize pigpio
    // ═══════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "🔧 Initializing GPIO library...";
    if (gpioInitialise() < 0) {
        qCritical() << "❌ Failed to initialize pigpio!";
        qCritical() << "   Make sure to run with sudo: sudo ./VehicleControlECU_Standalone";
        return -1;
    }
    qDebug() << "✅ GPIO library initialized";
    
    // ═══════════════════════════════════════════════════════
    // 2. Initialize PiRacer Hardware
    // ═══════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "🚗 Initializing PiRacer hardware...";
    PiRacerController piracerController;
    g_piracerController = &piracerController;
    
    if (!piracerController.initialize()) {
        qCritical() << "❌ Failed to initialize PiRacer hardware!";
        gpioTerminate();
        return -1;
    }
    
    // ═══════════════════════════════════════════════════════
    // 3. Initialize Gamepad
    // ═══════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "🎮 Initializing gamepad...";
    GamepadHandler gamepadHandler;
    
    if (gamepadHandler.initialize()) {
        // Connect gamepad to PiRacer
        QObject::connect(&gamepadHandler, &GamepadHandler::gearChangeRequested,
                        &piracerController, &PiRacerController::setGearPosition);
        
        QObject::connect(&gamepadHandler, &GamepadHandler::steeringChanged,
                        &piracerController, &PiRacerController::setSteeringPercent);
        
        QObject::connect(&gamepadHandler, &GamepadHandler::throttleChanged,
                        &piracerController, &PiRacerController::setThrottlePercent);
        
        gamepadHandler.start();
        qDebug() << "✅ Gamepad controls active";
    } else {
        qWarning() << "⚠️  Gamepad not found - manual control only";
    }
    
    // ═══════════════════════════════════════════════════════
    // 4. Setup Status Display Timer
    // ═══════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "📊 Setting up status display...";
    
    QTimer* statusTimer = new QTimer(&app);
    QObject::connect(statusTimer, &QTimer::timeout, [&piracerController]() {
        QString gear = piracerController.getCurrentGear();
        uint16_t speed = piracerController.getCurrentSpeed();
        uint8_t battery = piracerController.getBatteryLevel();
        
        qDebug() << "📊 [Status]"
                 << "Gear:" << gear
                 << "| Speed:" << speed << "km/h"
                 << "| Battery:" << battery << "%";
    });
    statusTimer->start(2000);  // 2초마다 상태 출력
    
    // ═══════════════════════════════════════════════════════
    // 5. Ready
    // ═══════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "✅ VehicleControlECU is running! (Standalone Mode)";
    qDebug() << "";
    qDebug() << "📌 Current State:";
    qDebug() << "   - Gear:" << piracerController.getCurrentGear();
    qDebug() << "   - Speed:" << piracerController.getCurrentSpeed() << "km/h";
    qDebug() << "   - Battery:" << piracerController.getBatteryLevel() << "%";
    qDebug() << "";
    qDebug() << "🎮 Gamepad Controls:";
    qDebug() << "   A = Drive   B = Park   X = Neutral   Y = Reverse";
    qDebug() << "   Left Analog = Steering   Right Analog Y = Throttle";
    qDebug() << "";
    qDebug() << "Press Ctrl+C to stop...";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    // ═══════════════════════════════════════════════════════
    // Run Event Loop
    // ═══════════════════════════════════════════════════════
    int result = app.exec();
    
    // ═══════════════════════════════════════════════════════
    // Cleanup
    // ═══════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "Shutting down...";
    gamepadHandler.stop();
    piracerController.setThrottlePercent(0.0f);
    piracerController.setSteeringPercent(0.0f);
    gpioTerminate();
    qDebug() << "✅ Cleanup complete";
    
    return result;
}
