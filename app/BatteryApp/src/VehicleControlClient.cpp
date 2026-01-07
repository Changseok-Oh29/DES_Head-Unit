#include "VehicleControlClient.h"
#include <QDebug>
#include <functional>
#include <cstdlib>

VehicleControlClient::VehicleControlClient(QObject *parent)
    : QObject(parent)
    , m_batteryLevel(0)
    , m_serviceAvailable(false)
    , m_batteryHistoryIndex(0)
    , m_batteryHistoryCount(0)
{
    // Initialize battery history buffer
    for (int i = 0; i < BATTERY_FILTER_SIZE; i++) {
        m_batteryHistory[i] = 0;
    }
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
    const std::string connection = "BatteryApp_client";

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

    qDebug() << "Event subscriptions setup complete";
}

void VehicleControlClient::onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp)
{
    Q_UNUSED(gear);
    Q_UNUSED(speed);
    Q_UNUSED(timestamp);

    // Smooth and update battery level
    int smoothedBattery = smoothBatteryLevel(battery);
    if (m_batteryLevel != smoothedBattery) {
        m_batteryLevel = smoothedBattery;
        emit batteryLevelChanged(m_batteryLevel);
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

int VehicleControlClient::smoothBatteryLevel(int rawLevel)
{
    // Add new value to circular buffer
    m_batteryHistory[m_batteryHistoryIndex] = rawLevel;
    m_batteryHistoryIndex = (m_batteryHistoryIndex + 1) % BATTERY_FILTER_SIZE;

    if (m_batteryHistoryCount < BATTERY_FILTER_SIZE) {
        m_batteryHistoryCount++;
    }

    // Calculate moving average
    int sum = 0;
    for (int i = 0; i < m_batteryHistoryCount; i++) {
        sum += m_batteryHistory[i];
    }

    int smoothed = sum / m_batteryHistoryCount;

    // Additional stability: only update if change is significant (>= 2%)
    if (m_batteryHistoryCount >= BATTERY_FILTER_SIZE) {
        int diff = std::abs(smoothed - m_batteryLevel);
        if (diff < 2) {
            return m_batteryLevel;  // Keep current value for small changes
        }
    }

    return smoothed;
}
