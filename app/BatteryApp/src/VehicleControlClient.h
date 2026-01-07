#ifndef VEHICLECONTROLCLIENT_H
#define VEHICLECONTROLCLIENT_H

#include <QObject>
#include <QString>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/vehiclecontrol/VehicleControlProxy.hpp>

using namespace v1::vehiclecontrol;

/**
 * @brief VehicleControl vsomeip client for BatteryApp
 *
 * Subscribes to VehicleControlECU running on Raspberry Pi
 * and receives vehicle state updates (battery level)
 */
class VehicleControlClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
    Q_PROPERTY(bool serviceAvailable READ serviceAvailable NOTIFY serviceAvailableChanged)

public:
    explicit VehicleControlClient(QObject *parent = nullptr);
    virtual ~VehicleControlClient();

    // Property getters
    int batteryLevel() const { return m_batteryLevel; }
    bool serviceAvailable() const { return m_serviceAvailable; }

    // Initialize connection
    void initialize();

signals:
    void batteryLevelChanged(int level);
    void serviceAvailableChanged(bool available);

private:
    // CommonAPI proxy
    std::shared_ptr<VehicleControlProxy<>> m_proxy;
    std::shared_ptr<CommonAPI::Runtime> m_runtime;

    // Current state
    int m_batteryLevel;
    bool m_serviceAvailable;

    // Smoothing filter for battery level
    static const int BATTERY_FILTER_SIZE = 10;
    int m_batteryHistory[BATTERY_FILTER_SIZE];
    int m_batteryHistoryIndex;
    int m_batteryHistoryCount;

    // Event subscriptions
    void setupEventSubscriptions();
    void onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp);
    void onAvailabilityChanged(CommonAPI::AvailabilityStatus status);

    // Helper functions
    int smoothBatteryLevel(int rawLevel);
};

#endif // VEHICLECONTROLCLIENT_H
