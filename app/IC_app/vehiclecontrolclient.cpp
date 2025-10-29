#include "vehiclecontrolclient.h"
#include <QDebug>
#include <functional>

VehicleControlClient::VehicleControlClient(QObject *parent)
    : QObject(parent)
    , m_currentGear("P")
    , m_currentSpeed(0)
    , m_batteryLevel(0)
    , m_serviceAvailable(false)
{
    qDebug() << "VehicleControlClient created";
}

VehicleControlClient::~VehicleControlClient()
{
    if (m_proxy) {
        m_proxy.reset();
    }
    qDebug() << "VehicleControlClient destroyed";
}

void VehicleControlClient::initialize()
{
    qDebug() << "🔌 Initializing VehicleControl vsomeip client...";
    
    // Get CommonAPI runtime
    m_runtime = CommonAPI::Runtime::get();
    if (!m_runtime) {
        qCritical() << "❌ Failed to get CommonAPI runtime!";
        return;
    }
    
    // Build proxy
    const std::string domain = "local";
    const std::string instance = "vehiclecontrol.VehicleControl";
    const std::string connection = "IC_app_client";
    
    m_proxy = m_runtime->buildProxy<VehicleControlProxy>(domain, instance, connection);
    
    if (!m_proxy) {
        qCritical() << "❌ Failed to build VehicleControl proxy!";
        return;
    }
    
    qDebug() << "✅ VehicleControl proxy created";
    qDebug() << "   Domain:" << QString::fromStdString(domain);
    qDebug() << "   Instance:" << QString::fromStdString(instance);
    
    // Subscribe to availability status
    m_proxy->getProxyStatusEvent().subscribe(
        std::bind(&VehicleControlClient::onAvailabilityChanged, this, std::placeholders::_1)
    );
    
    // Setup event subscriptions
    setupEventSubscriptions();
    
    qDebug() << "✅ VehicleControlClient initialized";
}

void VehicleControlClient::setupEventSubscriptions()
{
    if (!m_proxy) {
        qWarning() << "Cannot setup subscriptions: proxy is null";
        return;
    }
    
    qDebug() << "📡 Subscribing to VehicleControl events...";
    
    // Subscribe to vehicleStateChanged event (primary - 10Hz)
    m_proxy->getVehicleStateChangedEvent().subscribe(
        [this](std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp) {
            this->onVehicleStateChanged(gear, speed, battery, timestamp);
        }
    );
    
    // Subscribe to gearChanged event (secondary - event-driven)
    m_proxy->getGearChangedEvent().subscribe(
        [this](std::string newGear, std::string oldGear, uint64_t timestamp) {
            this->onGearChanged(newGear, oldGear, timestamp);
        }
    );
    
    qDebug() << "✅ Event subscriptions setup complete";
}

void VehicleControlClient::onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp)
{
    QString qGear = QString::fromStdString(gear);
    
    // Update and emit signals only if changed
    bool changed = false;
    
    if (m_currentGear != qGear) {
        m_currentGear = qGear;
        emit currentGearChanged(m_currentGear);
        changed = true;
    }
    
    if (m_currentSpeed != speed) {
        m_currentSpeed = speed;
        emit currentSpeedChanged(m_currentSpeed);
        changed = true;
    }
    
    if (m_batteryLevel != battery) {
        m_batteryLevel = battery;
        emit batteryLevelChanged(m_batteryLevel);
        changed = true;
    }
    
    // Log periodically (every 10 updates = 1 second at 10Hz)
    static int updateCount = 0;
    if (changed || (++updateCount % 10 == 0)) {
        qDebug() << "📡 [VehicleState]"
                 << "Gear:" << m_currentGear
                 << "Speed:" << m_currentSpeed << "km/h"
                 << "Battery:" << m_batteryLevel << "%"
                 << "@ timestamp:" << timestamp;
    }
}

void VehicleControlClient::onGearChanged(std::string newGear, std::string oldGear, uint64_t timestamp)
{
    QString qNewGear = QString::fromStdString(newGear);
    QString qOldGear = QString::fromStdString(oldGear);
    
    qDebug() << "📡 [GearChanged]" << qOldGear << "→" << qNewGear
             << "@ timestamp:" << timestamp;
    
    // Update gear if different (should match vehicleStateChanged)
    if (m_currentGear != qNewGear) {
        m_currentGear = qNewGear;
        emit currentGearChanged(m_currentGear);
    }
}

void VehicleControlClient::onAvailabilityChanged(CommonAPI::AvailabilityStatus status)
{
    bool wasAvailable = m_serviceAvailable;
    m_serviceAvailable = (status == CommonAPI::AvailabilityStatus::AVAILABLE);
    
    if (m_serviceAvailable != wasAvailable) {
        qDebug() << "🔗 VehicleControl service availability changed:"
                 << (m_serviceAvailable ? "AVAILABLE ✅" : "NOT AVAILABLE ⚠️");
        emit serviceAvailableChanged(m_serviceAvailable);
    }
    
    if (m_serviceAvailable) {
        qDebug() << "✅ VehicleControlECU service is now available on Raspberry Pi!";
    } else {
        qWarning() << "⚠️  VehicleControlECU service is not available";
        qWarning() << "   → Make sure VehicleControlECU is running on Raspberry Pi";
    }
}
