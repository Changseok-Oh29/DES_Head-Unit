#ifndef MOCK_VEHICLE_SERVICE_H
#define MOCK_VEHICLE_SERVICE_H

#include <QObject>
#include <QTimer>

class MockVehicleService : public QObject {
    Q_OBJECT
    Q_PROPERTY(int currentGear READ currentGear NOTIFY gearChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryChanged)
    Q_PROPERTY(float currentSpeed READ currentSpeed NOTIFY speedChanged)
    Q_PROPERTY(bool engineStatus READ engineStatus NOTIFY engineStatusChanged)

public:
    explicit MockVehicleService(QObject *parent = nullptr);

    // Property getters
    int currentGear() const { return m_currentGear; }
    int batteryLevel() const { return m_batteryLevel; }
    float currentSpeed() const { return m_currentSpeed; }
    bool engineStatus() const { return m_engineStatus; }

public slots:
    void setGear(int gear);
    void setEngineStatus(bool status);
    void emergencyStop();

signals:
    void gearChanged(int gear);
    void batteryChanged(int level);
    void speedChanged(float speed);
    void engineStatusChanged(bool status);

private slots:
    void updateSimulation();

private:
    QTimer* m_timer;
    int m_currentGear;
    int m_batteryLevel;
    float m_currentSpeed;
    bool m_engineStatus;

    void initializeData();
};

#endif // MOCK_VEHICLE_SERVICE_H
