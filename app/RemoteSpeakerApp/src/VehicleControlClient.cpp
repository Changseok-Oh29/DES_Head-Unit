#include "VehicleControlClient.h"
#include <QDebug>
#include <functional>

VehicleControlClient::VehicleControlClient(QObject *parent)
    : QObject(parent)
    , m_currentGear("P")
    , m_currentDistance(200)  // Default: far distance (no beep)
    , m_serviceAvailable(false)
{
    qDebug() << "[RemoteSpeakerApp] VehicleControlClient created";
}

VehicleControlClient::~VehicleControlClient()
{
    if (m_proxy) {
        m_proxy.reset();
    }
    qDebug() << "[RemoteSpeakerApp] VehicleControlClient destroyed";
}

void VehicleControlClient::initialize()
{
    qDebug() << "[RemoteSpeakerApp] Initializing VehicleControl vsomeip client...";

    // Get CommonAPI runtime
    m_runtime = CommonAPI::Runtime::get();
    if (!m_runtime) {
        qCritical() << "[RemoteSpeakerApp] Failed to get CommonAPI runtime!";
        return;
    }

    // Build proxy
    const std::string domain = "local";
    const std::string instance = "vehiclecontrol.VehicleControl";
    const std::string connection = "RemoteSpeakerApp_client";

    m_proxy = m_runtime->buildProxy<VehicleControlProxy>(domain, instance, connection);

    if (!m_proxy) {
        qCritical() << "[RemoteSpeakerApp] Failed to build VehicleControl proxy!";
        return;
    }

    qDebug() << "[RemoteSpeakerApp] VehicleControl proxy created";
    qDebug() << "   Domain:" << QString::fromStdString(domain);
    qDebug() << "   Instance:" << QString::fromStdString(instance);

    // Subscribe to availability status
    m_proxy->getProxyStatusEvent().subscribe(
        std::bind(&VehicleControlClient::onAvailabilityChanged, this, std::placeholders::_1)
    );

    // Setup event subscriptions
    setupEventSubscriptions();

    qDebug() << "[RemoteSpeakerApp] VehicleControlClient initialized";
}

void VehicleControlClient::setupEventSubscriptions()
{
    if (!m_proxy) {
        qWarning() << "[RemoteSpeakerApp] Cannot setup subscriptions: proxy is null";
        return;
    }

    qDebug() << "[RemoteSpeakerApp] Subscribing to VehicleControl events...";

    // Subscribe to gearDistanceChanged event (primary source for distance)
    m_proxy->getGearDistanceChangedEvent().subscribe(
        [this](std::string newGear, std::string oldGear, uint16_t distance, uint64_t timestamp) {
            this->onGearDistanceChanged(newGear, oldGear, distance, timestamp);
        }
    );

    // Subscribe to vehicleStateChanged event (for gear updates)
    m_proxy->getVehicleStateChangedEvent().subscribe(
        [this](std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp) {
            this->onVehicleStateChanged(gear, speed, battery, timestamp);
        }
    );

    qDebug() << "[RemoteSpeakerApp] Event subscriptions setup complete";
}

void VehicleControlClient::onGearDistanceChanged(std::string newGear, std::string oldGear, uint16_t distance, uint64_t timestamp)
{
    Q_UNUSED(oldGear);
    Q_UNUSED(timestamp);

    QString qNewGear = QString::fromStdString(newGear);

    // Update gear if changed
    if (m_currentGear != qNewGear) {
        m_currentGear = qNewGear;
        emit currentGearChanged(m_currentGear);
        qDebug() << "[RemoteSpeakerApp] Gear changed to:" << m_currentGear;
    }

    // Update distance (important for beep control)
    int newDistance = static_cast<int>(distance);
    if (m_currentDistance != newDistance) {
        m_currentDistance = newDistance;
        emit currentDistanceChanged(m_currentDistance);
    }
}

void VehicleControlClient::onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp)
{
    Q_UNUSED(speed);
    Q_UNUSED(battery);
    Q_UNUSED(timestamp);

    QString qGear = QString::fromStdString(gear);

    // Update gear only if changed
    if (m_currentGear != qGear) {
        m_currentGear = qGear;
        emit currentGearChanged(m_currentGear);
    }
}

void VehicleControlClient::onAvailabilityChanged(CommonAPI::AvailabilityStatus status)
{
    bool wasAvailable = m_serviceAvailable;
    m_serviceAvailable = (status == CommonAPI::AvailabilityStatus::AVAILABLE);

    if (m_serviceAvailable != wasAvailable) {
        qDebug() << "[RemoteSpeakerApp] VehicleControl service availability changed:"
                 << (m_serviceAvailable ? "AVAILABLE" : "NOT AVAILABLE");
        emit serviceAvailableChanged(m_serviceAvailable);
    }

    if (m_serviceAvailable) {
        qDebug() << "[RemoteSpeakerApp] VehicleControlECU service is now available!";
    } else {
        qWarning() << "[RemoteSpeakerApp] VehicleControlECU service is not available";
    }
}
