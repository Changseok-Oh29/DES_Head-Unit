#include <QCoreApplication>
#include <QDebug>
#include <QTimer>
#include <CommonAPI/CommonAPI.hpp>
#include "MockStubImpl.h"

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════════
    // Environment variables
    // ═══════════════════════════════════════════════════════════
    if (qgetenv("VSOMEIP_APPLICATION_NAME").isEmpty()) {
        qputenv("VSOMEIP_APPLICATION_NAME", "VehicleControlMock");
    }

    if (qgetenv("VSOMEIP_CONFIGURATION").isEmpty()) {
        qputenv("VSOMEIP_CONFIGURATION", "/home/seame/PDC/headunit/DES_Head-Unit/app/VehicleControlMock/config/vsomeip_mock.json");
    }

    if (qgetenv("COMMONAPI_CONFIG").isEmpty()) {
        qputenv("COMMONAPI_CONFIG", "/home/seame/PDC/headunit/DES_Head-Unit/commonapi/commonapi.ini");
    }

    QCoreApplication app(argc, argv);
    app.setApplicationName("VehicleControlMock");
    app.setApplicationVersion("1.0");

    qDebug() << "";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "VehicleControlMock - PDC Test Service";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "";
    qDebug() << "Environment Configuration:";
    qDebug() << "   VSOMEIP_APPLICATION_NAME:" << qgetenv("VSOMEIP_APPLICATION_NAME");
    qDebug() << "   VSOMEIP_CONFIGURATION:" << qgetenv("VSOMEIP_CONFIGURATION");
    qDebug() << "   COMMONAPI_CONFIG:" << qgetenv("COMMONAPI_CONFIG");
    qDebug() << "";

    // ═══════════════════════════════════════════════════════════
    // CommonAPI Service Registration
    // ═══════════════════════════════════════════════════════════
    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    if (!runtime) {
        qCritical() << "Failed to get CommonAPI runtime!";
        return -1;
    }

    // Create mock stub
    std::shared_ptr<MockStubImpl> mockStub = std::make_shared<MockStubImpl>();

    // Register service
    const std::string domain = "local";
    const std::string instance = "vehiclecontrol.VehicleControl";
    const std::string connection = "VehicleControlMock";

    bool registered = runtime->registerService(domain, instance, mockStub, connection);

    if (!registered) {
        qCritical() << "Failed to register VehicleControl service!";
        return -1;
    }

    qDebug() << "VehicleControl service registered successfully!";
    qDebug() << "   Domain:" << QString::fromStdString(domain);
    qDebug() << "   Instance:" << QString::fromStdString(instance);
    qDebug() << "";

    // ═══════════════════════════════════════════════════════════
    // Start continuous distance simulation immediately
    // The simulation runs continuously for testing purposes
    // ═══════════════════════════════════════════════════════════
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Mock service running. Press Ctrl+C to stop.";
    qDebug() << "";
    qDebug() << "Starting continuous PDC distance simulation...";
    qDebug() << "  - Distance cycles from 60cm to 5cm and repeats";
    qDebug() << "  - GearApp can change gear to control PDCApp visibility";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "";

    // Start the continuous simulation
    mockStub->startSimulation();

    return app.exec();
}
