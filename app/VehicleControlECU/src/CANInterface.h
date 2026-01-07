#ifndef CANINTERFACE_H
#define CANINTERFACE_H

#include <QObject>
#include <QMutex>
#include <QTimer>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/can.h>
#include <linux/can/raw.h>

// CAN ID from Arduino
#define ARDUINO_SPEED_ID 0x0F6

class CANInterface : public QObject
{
    Q_OBJECT

public:
    explicit CANInterface(QObject *parent = nullptr);
    ~CANInterface();

    bool initialize(const QString &interface = "can0");
    void shutdown();
    bool isConnected() const { return m_isConnected; }

    // Get current speed in km/h (converted from cm/s)
    float getCurrentSpeedKmh() const;
    
    // Get raw speed in cm/s
    float getCurrentSpeedCms() const;

    // Get filtered distance in cm
    float getCurrentDistanceCm() const;

signals:
    void speedDataReceived(float speedCms);
    void distanceDataReceived(float distanceCm);  // NEW: Distance data signal
    void canError(const QString &error);

private slots:
    void receiveCANMessages();

private:
    bool setupCANInterface(const QString &interface);
    void processCANFrame(const struct can_frame &frame);
    float parseSpeedData(const uint8_t *data);

    // NEW: Distance parsing and filtering methods
    float parseDistanceData(const uint8_t *data);
    float filterDistance(float rawDistance);
    bool isValidDistance(float distance) const;
    bool isOutlier(float distance) const;

    int m_canSocket;
    bool m_isConnected;
    QString m_interfaceName;
    QTimer *m_receiveTimer;

    float m_currentSpeedCms;
    mutable QMutex m_dataMutex;

    // NEW: Distance filter state variables
    float m_currentDistanceCm;      // Filtered distance value
    float m_previousRawDistance;    // Previous raw value for outlier detection
    float m_emaDistance;            // EMA filter state
    bool m_distanceFilterInitialized;

    // NEW: Filter configuration constants
    static constexpr float DISTANCE_EMA_ALPHA = 0.2f;        // EMA smoothing (20% new, 80% old)
    static constexpr float DISTANCE_MAX_VALID = 200.0f;      // Max valid distance (cm)
    static constexpr float DISTANCE_MIN_VALID = 2.0f;        // Min valid distance (cm)
    static constexpr float DISTANCE_OUTLIER_THRESHOLD = 30.0f; // Max jump between readings (cm)
};

#endif // CANINTERFACE_H
