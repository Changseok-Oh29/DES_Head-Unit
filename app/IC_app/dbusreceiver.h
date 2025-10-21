#ifndef DBUSRECEIVER_H
#define DBUSRECEIVER_H

#include <QObject>
#include <QDBusInterface>

class DBusReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gear READ gear NOTIFY gearChanged)
    Q_PROPERTY(int batteryPercentage READ batteryPercentage NOTIFY batteryChanged)
    Q_PROPERTY(double current READ current NOTIFY currentChanged)

public:
    explicit DBusReceiver(QObject *parent = nullptr);

    // Function to request initial status from QML/main.cpp
    Q_INVOKABLE void requestInitialStatus();

    // Function to request initial gear value
    QString getGear();

    // Getter functions for QML properties
    QString gear() const { return m_gear; }
    int batteryPercentage() const { return m_batteryPercentage; }
    double current() const { return m_current; }

signals:
    void gearChanged();
    void batteryChanged();
    void currentChanged();

private slots:
    // Slot to handle gear change signal
    void onGearChanged(const QString &newGear);
    // Slot to handle charging status change signal
    void onChargingStatusChanged(double newCurrent);
    // Slot to handle periodic battery percentage signal
    void onPercentageChanged(int newPercentage);

private:
    // D-Bus interfaces
    QDBusInterface *vehicleIface;
    QDBusInterface *batteryIface;

    // Member variables
    QString m_gear;
    int m_batteryPercentage;
    double m_current;
};

#endif // DBUSRECEIVER_H
