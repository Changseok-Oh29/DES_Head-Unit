#include <QCoreApplication>
#include <QDebug>
#include <CommonAPI/CommonAPI.hpp>
#include "VehicleControlStubImpl.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    qDebug() << "========================================";
    qDebug() << "VehicleControl Mock Service (Ubuntu)";
    qDebug() << "========================================";
    qDebug() << "";
    qDebug() << "This is a mock VehicleControl service for";
    qDebug() << "testing GearApp <-> AmbientApp communication";
    qDebug() << "on Ubuntu without Raspberry Pi hardware.";
    qDebug() << "";
    qDebug() << "Service Info:";
    qDebug() << "  Domain:   local";
    qDebug() << "  Instance: vehiclecontrol.VehicleControl";
    qDebug() << "  Service:  0x1234 (4660)";
    qDebug() << "  Instance: 0x5678 (22136)";
    qDebug() << "";
    qDebug() << "Features:";
    qDebug() << "  - RPC: setGearPosition(gear) -> success";
    qDebug() << "  - Event: gearChanged(new, old, timestamp)";
    qDebug() << "  - Event: vehicleStateChanged(gear, speed, battery, ts)";
    qDebug() << "";
    qDebug() << "========================================";
    qDebug() << "";

    // Initialize CommonAPI runtime
    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    if (!runtime) {
        qCritical() << "Failed to get CommonAPI runtime!";
        return 1;
    }
    qDebug() << "✓ CommonAPI runtime initialized";

    // Create and register service
    const std::string domain = "local";
    const std::string instance = "vehiclecontrol.VehicleControl";
    const std::string connection = "service-sample";

    std::shared_ptr<VehicleControlStubImpl> service = std::make_shared<VehicleControlStubImpl>();

    bool registered = runtime->registerService(domain, instance, service, connection);
    if (!registered) {
        qCritical() << "Failed to register VehicleControl service!";
        qCritical() << "  Domain:" << QString::fromStdString(domain);
        qCritical() << "  Instance:" << QString::fromStdString(instance);
        return 1;
    }

    qDebug() << "✓ VehicleControl service registered successfully";
    qDebug() << "  Domain:" << QString::fromStdString(domain);
    qDebug() << "  Instance:" << QString::fromStdString(instance);
    qDebug() << "";
    qDebug() << "🚀 Service running...";
    qDebug() << "   Waiting for GearApp connections...";
    qDebug() << "   Broadcasting vehicle state at 10Hz";
    qDebug() << "";
    qDebug() << "Press Ctrl+C to stop";
    qDebug() << "";

    return app.exec();
}
