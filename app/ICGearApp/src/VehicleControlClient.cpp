#include "VehicleControlClient.h"
#include <QDebug>
#include <functional>

VehicleControlClient::VehicleControlClient(QObject *parent)
    : QObject(parent)
    , m_currentGear("P")
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
    qDebug() << "Initializing VehicleControl vsomeip client...";

    // Get CommonAPI runtime
    m_runtime = CommonAPI::Runtime::get();
    if (!m_runtime) {
        qCritical() << "Failed to get CommonAPI runtime!";
        return;
    }

    // Build proxy
    const std::string domain = "local";
    const std::string instance = "vehiclecontrol.VehicleControl";
    const std::string connection = "ICGearApp_client";

    m_proxy = m_runtime->buildProxy<VehicleControlProxy>(domain, instance, connection);

    if (!m_proxy) {
        qCritical() << "Failed to build VehicleControl proxy!";
        return;
    }

    qDebug() << "VehicleControl proxy created";
    qDebug() << "   Domain:" << QString::fromStdString(domain);
    qDebug() << "   Instance:" << QString::fromStdString(instance);

    // Subscribe to availability status
    m_proxy->getProxyStatusEvent().subscribe(
        std::bind(&VehicleControlClient::onAvailabilityChanged, this, std::placeholders::_1)
    );

    // Setup event subscriptions
    setupEventSubscriptions();

    qDebug() << "VehicleControlClient initialized";
}

void VehicleControlClient::setupEventSubscriptions()
{
    if (!m_proxy) {
        qWarning() << "Cannot setup subscriptions: proxy is null";
        return;
    }

    qDebug() << "Subscribing to VehicleControl events...";

    // Subscribe to vehicleStateChanged event (10Hz)
    m_proxy->getVehicleStateChangedEvent().subscribe(
        [this](std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp) {
            this->onVehicleStateChanged(gear, speed, battery, timestamp);
        }
    );

    // Subscribe to gearDistanceChanged event (event-driven)
    m_proxy->getGearDistanceChangedEvent().subscribe(
        [this](std::string newGear, std::string oldGear, uint16_t distance, uint64_t timestamp) {
            this->onGearDistanceChanged(newGear, oldGear, distance, timestamp);
        }
    );

    qDebug() << "Event subscriptions setup complete";
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

void VehicleControlClient::onGearDistanceChanged(std::string newGear, std::string oldGear, uint16_t distance, uint64_t timestamp)
{
    Q_UNUSED(oldGear);
    Q_UNUSED(distance);  // ICGearApp doesn't need distance
    Q_UNUSED(timestamp);

    QString qNewGear = QString::fromStdString(newGear);

    // Update gear if different
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
        qDebug() << "VehicleControl service availability changed:"
                 << (m_serviceAvailable ? "AVAILABLE" : "NOT AVAILABLE");
        emit serviceAvailableChanged(m_serviceAvailable);
    }

    if (m_serviceAvailable) {
        qDebug() << "VehicleControlECU service is now available!";
    } else {
        qWarning() << "VehicleControlECU service is not available";
    }
}
