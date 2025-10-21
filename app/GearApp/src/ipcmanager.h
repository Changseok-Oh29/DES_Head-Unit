#ifndef IPCMANAGER_H
#define IPCMANAGER_H

#include <QObject>
#include <QTimer>
#include <QUdpSocket>
#include <QJsonObject>
#include <QJsonDocument>

class IpcManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gearPosition READ gearPosition WRITE setGearPosition NOTIFY gearPositionChanged)
    Q_PROPERTY(bool ambientLightEnabled READ ambientLightEnabled WRITE setAmbientLightEnabled NOTIFY ambientLightEnabledChanged)
    Q_PROPERTY(QString ambientColor READ ambientColor WRITE setAmbientColor NOTIFY ambientColorChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)

public:
    explicit IpcManager(QObject *parent = nullptr);
    
    QString gearPosition() const { return m_gearPosition; }
    bool ambientLightEnabled() const { return m_ambientLightEnabled; }
    QString ambientColor() const { return m_ambientColor; }
    bool isConnected() const { return m_isConnected; }

public slots:
    void setGearPosition(const QString &position);
    void setAmbientLightEnabled(bool enabled);
    void setAmbientColor(const QString &color);
    void sendHeartbeat();

signals:
    void gearPositionChanged();
    void ambientLightEnabledChanged();
    void ambientColorChanged();
    void connectionStateChanged();
    void speedDataReceived(int speed);
    void rpmDataReceived(int rpm);
    
    // New signal: IC로부터 gear status 수신 시 발생
    void gearStatusReceivedFromIC(QString gear);

private slots:
    void onDataReceived();
    void onHeartbeatTimeout();
    void reconnectSocket();

private:
    void sendMessage(const QJsonObject &message);
    void processReceivedMessage(const QJsonObject &message);
    void updateConnectionState(bool connected);

    QString m_gearPosition;
    bool m_ambientLightEnabled;
    QString m_ambientColor;
    bool m_isConnected;
    
    QUdpSocket *m_socket;
    QTimer *m_heartbeatTimer;
    QTimer *m_connectionTimer;
    
    static const quint16 IC_PORT = 12345;  // Instrument Cluster port
    static const quint16 HU_PORT = 12346;  // Head Unit port
    static const QString IC_ADDRESS;       // Will be "127.0.0.1" for local testing
};

#endif // IPCMANAGER_H
