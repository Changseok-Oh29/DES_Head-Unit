#ifndef VEHICLECONTROLCLIENT_H
#define VEHICLECONTROLCLIENT_H

#include <QObject>
#include <QString>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/vehiclecontrol/VehicleControlProxy.hpp>

using namespace v1::vehiclecontrol;

/**
 * @brief VehicleControl vsomeip client for IC_app
 * 
 * Subscribes to VehicleControlECU running on Raspberry Pi
 * and receives vehicle state updates (gear, speed, battery)
 */
class VehicleControlClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentGear READ currentGear NOTIFY currentGearChanged)
    Q_PROPERTY(int currentSpeed READ currentSpeed NOTIFY currentSpeedChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
    Q_PROPERTY(bool serviceAvailable READ serviceAvailable NOTIFY serviceAvailableChanged)
    Q_PROPERTY(bool isCharging READ isCharging NOTIFY isChargingChanged)  // ← 충전 중 여부

public:
    explicit VehicleControlClient(QObject *parent = nullptr);
    virtual ~VehicleControlClient();

    // Property getters
    QString currentGear() const { return m_currentGear; }
    int currentSpeed() const { return m_currentSpeed; }
    int batteryLevel() const { return m_batteryLevel; }
    bool serviceAvailable() const { return m_serviceAvailable; }
    bool isCharging() const { return m_isCharging; }  // ← 충전 중 getter

    // Initialize connection
    void initialize();

signals:
    void currentGearChanged(const QString& gear);
    void currentSpeedChanged(int speed);
    void batteryLevelChanged(int level);
    void serviceAvailableChanged(bool available);
    void isChargingChanged(bool charging);  // ← 충전 중 signal

private:
    // CommonAPI proxy
    std::shared_ptr<VehicleControlProxy<>> m_proxy;
    std::shared_ptr<CommonAPI::Runtime> m_runtime;
    
    // Current state
    QString m_currentGear;
    int m_currentSpeed;
    int m_batteryLevel;
    int m_previousBatteryLevel;  // ← 이전 배터리 레벨 (충전 감지용)
    bool m_serviceAvailable;
    bool m_isCharging;  // ← 충전 중 상태
    
    // Smoothing filter for battery level
    static const int BATTERY_FILTER_SIZE = 5;  // ← 노이즈 필터
    int m_batteryHistory[BATTERY_FILTER_SIZE];
    int m_batteryHistoryIndex;
    int m_batteryHistoryCount;
    
    // Event subscriptions
    void setupEventSubscriptions();
    void onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp);
    void onGearChanged(std::string newGear, std::string oldGear, uint64_t timestamp);
    void onAvailabilityChanged(CommonAPI::AvailabilityStatus status);
    
    // Helper functions
    int smoothBatteryLevel(int rawLevel);  // ← 배터리 레벨 스무딩
    void detectCharging(int newLevel);     // ← 충전 감지
};

#endif // VEHICLECONTROLCLIENT_H
