#include "VehicleControlStubImpl.h"
#include <chrono>

VehicleControlStubImpl::VehicleControlStubImpl()
    : m_currentGear("P")
    , m_speed(0)
    , m_battery(85)
    , m_stateTimer(new QTimer(this))
{
    qDebug() << "VehicleControlStubImpl: Service created";
    qDebug() << "  Initial gear: P";
    qDebug() << "  Battery: 85%";

    // Broadcast vehicle state every 100ms (10Hz)
    connect(m_stateTimer, &QTimer::timeout, this, &VehicleControlStubImpl::broadcastVehicleState);
    m_stateTimer->start(100);
}

VehicleControlStubImpl::~VehicleControlStubImpl()
{
    qDebug() << "VehicleControlStubImpl: Service destroyed";
}

void VehicleControlStubImpl::setGearPosition(const std::shared_ptr<CommonAPI::ClientId> _client,
                                            std::string _gear,
                                            setGearPositionReply_t _reply)
{
    qDebug() << "VehicleControlStubImpl: setGearPosition() called";
    qDebug() << "  Requested gear:" << QString::fromStdString(_gear);

    // Validate gear
    if (_gear != "P" && _gear != "R" && _gear != "N" && _gear != "D") {
        qWarning() << "  Invalid gear! Must be P, R, N, or D";
        _reply(false);
        return;
    }

    std::string oldGear = m_currentGear;
    m_currentGear = _gear;

    // Update speed based on gear (mock behavior)
    if (_gear == "P" || _gear == "N") {
        m_speed = 0;
    } else if (_gear == "D") {
        m_speed = 25; // Mock forward speed
    } else if (_gear == "R") {
        m_speed = 10; // Mock reverse speed
    }

    qDebug() << "  Gear changed:" << QString::fromStdString(oldGear)
             << "->" << QString::fromStdString(m_currentGear);
    qDebug() << "  Speed:" << m_speed << "km/h";

    // Fire gearChanged event
    auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();

    fireGearChangedEvent(_gear, oldGear, timestamp);
    qDebug() << "  gearChanged event fired";

    _reply(true);
}

void VehicleControlStubImpl::broadcastVehicleState()
{
    // Simulate battery drain
    static int counter = 0;
    if (++counter >= 100) { // Every 10 seconds
        if (m_battery > 0) {
            m_battery--;
        }
        counter = 0;
    }

    auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();

    // Broadcast vehicle state
    fireVehicleStateChangedEvent(m_currentGear, m_speed, m_battery, timestamp);
}
