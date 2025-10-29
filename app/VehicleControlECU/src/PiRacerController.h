#ifndef PIRACERCONTROLLER_H
#define PIRACERCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <memory>
#include "../lib/Adafruit_PCA9685.hpp"
#include "BatteryMonitor.h"

class PiRacerController : public QObject
{
    Q_OBJECT
    
public:
    explicit PiRacerController(QObject *parent = nullptr);
    ~PiRacerController();
    
    bool initialize();
    
    // Vehicle control
    void setGearPosition(const QString& gear);
    void setSteeringPercent(float percent);  // -1.0 to 1.0
    void setThrottlePercent(float percent);  // -1.0 to 1.0
    
    // Vehicle state
    QString getCurrentGear() const { return m_currentGear; }
    uint16_t getCurrentSpeed() const { return m_currentSpeed; }
    uint8_t getBatteryLevel() const;
    
signals:
    void gearChanged(QString newGear, QString oldGear);
    void vehicleStateChanged(QString gear, uint16_t speed, uint8_t battery);
    
private:
    // Hardware
    std::unique_ptr<PCA9685> m_steeringController;
    std::unique_ptr<PCA9685> m_throttleController;
    std::unique_ptr<BatteryMonitor> m_batteryMonitor;
    
    // PWM Configuration
    const int PWM_RESOLUTION = 12;
    const int PWM_MAX_RAW_VALUE = 4095;  // 2^12 - 1
    const float PWM_FREQ_50HZ = 50.0f;
    const float PWM_WAVELENGTH_50HZ = 0.02f;  // 1/50Hz
    
    // PWM Channels
    const int PWM_STEERING_CHANNEL = 0;
    const int PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_1 = 5;
    const int PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_2 = 6;
    const int PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_PWM = 7;
    const int PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_1 = 1;
    const int PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_2 = 2;
    const int PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_PWM = 0;
    
    // State
    QString m_currentGear;
    uint16_t m_currentSpeed;
    float m_currentThrottle;
    
    // Helper functions
    float get50HzDutyCycleFromPercent(float value);
    void warmUp();
};

#endif // PIRACERCONTROLLER_H
