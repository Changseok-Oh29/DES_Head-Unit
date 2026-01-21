#include "VehicleControlClient.h"
#include <QDebug>
#include <functional>

VehicleControlClient::VehicleControlClient(QObject *parent)
    : QObject(parent)
    , m_currentGear("P")
    , m_isConnected(false)
{
    qDebug() << "[HU_MainApp] VehicleControlClient created";
}

VehicleControlClient::~VehicleControlClient()
{
    disconnectFromService();
    qDebug() << "[HU_MainApp] VehicleControlClient destroyed";
}

void VehicleControlClient::connectToService()
{
    qDebug() << "[HU_MainApp] Connecting to VehicleControl service...";

    // Get CommonAPI runtime
    m_runtime = CommonAPI::Runtime::get();
    if (!m_runtime) {
        qCritical() << "[HU_MainApp] Failed to get CommonAPI runtime!";
        emit connectedChanged(false);
        return;
    }

    // Build proxy
    const std::string domain = "local";
    const std::string instance = "vehiclecontrol.VehicleControl";
    const std::string connection = "HUMainApp_client";

    m_proxy = m_runtime->buildProxy<VehicleControlProxy>(domain, instance, connection);

    if (!m_proxy) {
        qCritical() << "[HU_MainApp] Failed to build VehicleControl proxy!";
        emit connectedChanged(false);
        return;
    }

    qDebug() << "[HU_MainApp] Proxy created successfully";

    // Subscribe to availability status
    m_proxy->getProxyStatusEvent().subscribe(
        std::bind(&VehicleControlClient::onAvailabilityChanged, this, std::placeholders::_1)
    );

    // Setup event subscriptions
    setupEventSubscriptions();

    qDebug() << "[HU_MainApp] Connected to VehicleControl service";
    qDebug() << "   Domain:" << QString::fromStdString(domain);
    qDebug() << "   Instance:" << QString::fromStdString(instance);
}

void VehicleControlClient::disconnectFromService()
{
    if (m_proxy) {
        qDebug() << "[HU_MainApp] Disconnecting from VehicleControl service...";
        m_proxy.reset();
        m_isConnected = false;
        emit connectedChanged(false);
    }
}

void VehicleControlClient::setupEventSubscriptions()
{
    if (!m_proxy) {
        qWarning() << "[HU_MainApp] Cannot setup subscriptions: proxy is null";
        return;
    }

    qDebug() << "[HU_MainApp] Subscribing to gearDistanceChanged events...";

    // Subscribe to gearDistanceChanged event
    m_proxy->getGearDistanceChangedEvent().subscribe(
        [this](std::string newGear, std::string oldGear, uint16_t /*distance*/, uint64_t timestamp) {
            this->onGearDistanceChanged(newGear, oldGear, timestamp);
        }
    );

    qDebug() << "[HU_MainApp] Event subscriptions setup complete";
}

void VehicleControlClient::onGearDistanceChanged(std::string newGear, std::string oldGear, uint64_t timestamp)
{
    QString qNewGear = QString::fromStdString(newGear);
    QString qOldGear = QString::fromStdString(oldGear);

    // Update gear if changed
    if (m_currentGear != qNewGear) {
        m_currentGear = qNewGear;
        emit currentGearChanged(m_currentGear);
        qDebug() << "[HU_MainApp] Gear changed:" << qOldGear << "->" << qNewGear;
    }
}

void VehicleControlClient::onAvailabilityChanged(CommonAPI::AvailabilityStatus status)
{
    bool wasConnected = m_isConnected;
    m_isConnected = (status == CommonAPI::AvailabilityStatus::AVAILABLE);

    if (m_isConnected != wasConnected) {
        qDebug() << "[HU_MainApp] Service availability changed:"
                 << (m_isConnected ? "AVAILABLE" : "NOT AVAILABLE");
        emit connectedChanged(m_isConnected);
    }

    if (m_isConnected) {
        qDebug() << "[HU_MainApp] VehicleControl service is now available!";
    } else {
        qWarning() << "[HU_MainApp] VehicleControl service is not available";
    }
}
