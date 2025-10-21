#include "dbusreceiver.h"
#include <QDBusReply>
#include <QDBusArgument>
#include <QtMath>

DBusReceiver::DBusReceiver(QObject *parent)
    : QObject(parent),
    m_gear("P"),
    m_batteryPercentage(0),
    m_current(0.0)
{
    // Match service, path, and interface names with Python server
    const QString service = "org.piracer.Battery";
    const QString path = "/org/piracer/Battery";
    const QString interface = "org.piracer.Battery";

    // Battery DBus interface setup
    batteryIface = new QDBusInterface(service, path, interface, QDBusConnection::sessionBus(), this);

    QDBusConnection::sessionBus().connect(
        service, path, interface, "chargingStatusChanged", this, SLOT(onChargingStatusChanged(double))
    );
    QDBusConnection::sessionBus().connect(
        service, path, interface, "percentageChanged", this, SLOT(onPercentageChanged(int))
    );

    // Vehicle Controller DBus interface (gear related)
    vehicleIface = new QDBusInterface(
        "org.piracer.VehicleController", "/org/piracer/VehicleController", "org.piracer.VehicleInterface",
        QDBusConnection::sessionBus(), this
    );

    QDBusConnection::sessionBus().connect(
        "org.piracer.VehicleController", "/org/piracer/VehicleController", "org.piracer.VehicleInterface",
        "gearChanged", this, SLOT(onGearChanged(QString))
    );

    getGear();
}

// Request initial values directly from server
void DBusReceiver::requestInitialStatus() {
    if (!batteryIface->isValid()) {
        return;
    }

    // Call GetInitialStatus method on the server
    QDBusMessage replyMsg = batteryIface->call("GetInitialStatus");
    QDBusReply<QDBusArgument> reply(replyMsg);

    if (reply.isValid()) {
        // Parse D-Bus tuple (structure)
        const QDBusArgument &arg = reply.value();
        arg.beginStructure();
        int percentage;
        double current;
        arg >> percentage >> current;
        arg.endStructure();

        // Update GUI with received values
        onPercentageChanged(percentage);
        onChargingStatusChanged(current);
    }
}

void DBusReceiver::onChargingStatusChanged(double newCurrent)
{
    if (qAbs(m_current - newCurrent) > 0.001) {
        m_current = newCurrent;
        emit currentChanged();
    }
}

void DBusReceiver::onPercentageChanged(int newPercentage)
{
    if (m_batteryPercentage != newPercentage) {
        m_batteryPercentage = newPercentage;
        emit batteryChanged();
    }
}

QString DBusReceiver::getGear() {
    if (!vehicleIface->isValid()) {
        return QString();
    }

    QDBusReply<QString> reply = vehicleIface->call("GetGear");
    if (reply.isValid()) {
        onGearChanged(reply.value());
        return reply.value();
    } else {
        return QString();
    }
}

void DBusReceiver::onGearChanged(const QString &newGear) {
    if (m_gear != newGear) {
        m_gear = newGear;
        emit gearChanged();
    }
}
