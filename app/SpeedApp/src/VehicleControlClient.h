#ifndef VEHICLECONTROLCLIENT_H
#define VEHICLECONTROLCLIENT_H

#include <QObject>
#include <QString>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/vehiclecontrol/VehicleControlProxy.hpp>

using namespace v1::vehiclecontrol;

/**
 * @brief VehicleControl vsomeip client for SpeedApp
 *
 * Subscribes to VehicleControlECU running on Raspberry Pi
 * and receives vehicle state updates (speed)
 */
class VehicleControlClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int currentSpeed READ currentSpeed NOTIFY currentSpeedChanged)
    Q_PROPERTY(bool serviceAvailable READ serviceAvailable NOTIFY serviceAvailableChanged)

public:
    explicit VehicleControlClient(QObject *parent = nullptr);
    virtual ~VehicleControlClient();

    // Property getters
    int currentSpeed() const { return m_currentSpeed; }
    bool serviceAvailable() const { return m_serviceAvailable; }

    // Initialize connection
    void initialize();

signals:
    void currentSpeedChanged(int speed);
    void serviceAvailableChanged(bool available);

private:
    // CommonAPI proxy
    std::shared_ptr<VehicleControlProxy<>> m_proxy;
    std::shared_ptr<CommonAPI::Runtime> m_runtime;

    // Current state
    int m_currentSpeed;
    bool m_serviceAvailable;

    // Event subscriptions
    void setupEventSubscriptions();
    void onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp);
    void onAvailabilityChanged(CommonAPI::AvailabilityStatus status);
};

#endif // VEHICLECONTROLCLIENT_H
