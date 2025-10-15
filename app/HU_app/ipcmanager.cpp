#include "ipcmanager.h"
#include <QHostAddress>
#include <QNetworkDatagram>
#include <QDebug>

const QString IpcManager::IC_ADDRESS = "127.0.0.1";

IpcManager::IpcManager(QObject *parent)
    : QObject(parent)
    , m_gearPosition("P")
    , m_ambientLightEnabled(true)  // 기본적으로 활성화
    , m_ambientColor("#3498db")    // 기본 파란색
    , m_isConnected(false)
    , m_socket(new QUdpSocket(this))
    , m_heartbeatTimer(new QTimer(this))
    , m_connectionTimer(new QTimer(this))
{
    // Setup UDP socket
    connect(m_socket, &QUdpSocket::readyRead,
            this, &IpcManager::onDataReceived);
    
    // Setup heartbeat timer
    m_heartbeatTimer->setInterval(5000); // 5 seconds
    connect(m_heartbeatTimer, &QTimer::timeout,
            this, &IpcManager::sendHeartbeat);
    
    // Setup connection monitoring timer
    m_connectionTimer->setInterval(15000); // 15 seconds timeout
    m_connectionTimer->setSingleShot(true);
    connect(m_connectionTimer, &QTimer::timeout,
            this, &IpcManager::onHeartbeatTimeout);
    
    // Bind socket to HU port
    if (m_socket->bind(QHostAddress::Any, HU_PORT)) {
        qDebug() << "IpcManager: Bound to port" << HU_PORT;
        m_heartbeatTimer->start();
        reconnectSocket();
    } else {
        qDebug() << "IpcManager: Failed to bind to port" << HU_PORT;
    }
}

void IpcManager::setGearPosition(const QString &position)
{
    if (m_gearPosition != position) {
        m_gearPosition = position;
        emit gearPositionChanged();
        
        // Send gear change to IC
        QJsonObject message;
        message["type"] = "gear_change";
        message["gear"] = position;
        message["timestamp"] = QDateTime::currentMSecsSinceEpoch();
        sendMessage(message);
        
        qDebug() << "IpcManager: Gear changed to" << position;
    }
}

void IpcManager::setAmbientLightEnabled(bool enabled)
{
    if (m_ambientLightEnabled != enabled) {
        m_ambientLightEnabled = enabled;
        emit ambientLightEnabledChanged();
        
        // Send ambient light state to IC
        QJsonObject message;
        message["type"] = "ambient_light";
        message["enabled"] = enabled;
        message["color"] = m_ambientColor;
        message["timestamp"] = QDateTime::currentMSecsSinceEpoch();
        sendMessage(message);
        
        qDebug() << "IpcManager: Ambient light" << (enabled ? "enabled" : "disabled");
    }
}

void IpcManager::setAmbientColor(const QString &color)
{
    if (m_ambientColor != color) {
        m_ambientColor = color;
        emit ambientColorChanged();
        
        // Send ambient color change to IC if enabled
        if (m_ambientLightEnabled) {
            QJsonObject message;
            message["type"] = "ambient_light";
            message["enabled"] = true;
            message["color"] = color;
            message["timestamp"] = QDateTime::currentMSecsSinceEpoch();
            sendMessage(message);
        }
        
        qDebug() << "IpcManager: Ambient color changed to" << color;
    }
}

void IpcManager::sendHeartbeat()
{
    QJsonObject message;
    message["type"] = "heartbeat";
    message["source"] = "head_unit";
    message["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    sendMessage(message);
    
    // Reset connection timer
    m_connectionTimer->start();
}

void IpcManager::sendMessage(const QJsonObject &message)
{
    QJsonDocument doc(message);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    
    qint64 written = m_socket->writeDatagram(data, QHostAddress(IC_ADDRESS), IC_PORT);
    if (written != data.size()) {
        qDebug() << "IpcManager: Failed to send complete message";
    }
}

void IpcManager::onDataReceived()
{
    while (m_socket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_socket->receiveDatagram();
        QByteArray data = datagram.data();
        
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(data, &error);
        
        if (error.error != QJsonParseError::NoError) {
            qDebug() << "IpcManager: JSON parse error:" << error.errorString();
            continue;
        }
        
        QJsonObject message = doc.object();
        processReceivedMessage(message);
    }
}

void IpcManager::processReceivedMessage(const QJsonObject &message)
{
    QString type = message["type"].toString();
    
    if (type == "heartbeat_response" || type == "heartbeat") {
        updateConnectionState(true);
        m_connectionTimer->start(); // Reset timeout
    }
    else if (type == "speed_data") {
        int speed = message["speed"].toInt();
        emit speedDataReceived(speed);
    }
    else if (type == "rpm_data") {
        int rpm = message["rpm"].toInt();
        emit rpmDataReceived(rpm);
    }
    else if (type == "gear_status") {
        // IC confirming gear change
        QString gear = message["gear"].toString();
        qDebug() << "IpcManager: IC confirmed gear:" << gear;
    }
    else {
        qDebug() << "IpcManager: Unknown message type:" << type;
    }
}

void IpcManager::onHeartbeatTimeout()
{
    qDebug() << "IpcManager: Connection timeout - IC not responding";
    updateConnectionState(false);
}

void IpcManager::reconnectSocket()
{
    // Send initial connection message
    QJsonObject message;
    message["type"] = "connect";
    message["source"] = "head_unit";
    message["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    sendMessage(message);
}

void IpcManager::updateConnectionState(bool connected)
{
    if (m_isConnected != connected) {
        m_isConnected = connected;
        emit connectionStateChanged();
        qDebug() << "IpcManager: Connection state changed to" << (connected ? "connected" : "disconnected");
    }
}
