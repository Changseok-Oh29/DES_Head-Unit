#ifndef GEARMANAGER_H
#define GEARMANAGER_H

#include <QObject>
#include <QString>
#include <QUdpSocket>
#include <QJsonObject>
#include <QDateTime>

class GearManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gearPosition READ gearPosition WRITE setGearPosition NOTIFY gearPositionChanged)

public:
    explicit GearManager(QObject *parent = nullptr);
    
    QString gearPosition() const { return m_gearPosition; }
    void setGearPosition(const QString &position);

public slots:
    // IC로부터 gear status 수신 시 호출 (IpcManager 연결용)
    void onGearStatusReceivedFromIC(const QString &gear);

signals:
    void gearPositionChanged(const QString &gear);

private:
    void sendGearChangeToIC(const QString &gear);
    
    QString m_gearPosition;
    QUdpSocket *m_socket;
    
    static const quint16 IC_PORT = 12345;  // Instrument Cluster port
    static const QString IC_ADDRESS;       // "127.0.0.1"
};

#endif // GEARMANAGER_H
