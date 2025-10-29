#include <QCoreApplication>
#include <QTimer>
#include <QDebug>
#include <QDateTime>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/vehiclecontrol/VehicleControlStubDefault.hpp>

// Mock VehicleControlStubImpl (완전 독립형 - PiRacerController 불필요)
class MockVehicleControlStub : public QObject, public v1::vehiclecontrol::VehicleControlStubDefault
{
    Q_OBJECT

public:
    MockVehicleControlStub() 
        : m_currentGear("N")
        , m_currentSpeed(0)
        , m_batteryLevel(0)
    {
        qDebug() << "✅ MockVehicleControlStub initialized";
        qDebug() << "   Initial state: Gear=N, Speed=0, Battery=0%";
        
        // Start periodic state broadcast (10Hz)
        m_timer = new QTimer(this);
        QObject::connect(m_timer, &QTimer::timeout, this, &MockVehicleControlStub::broadcastState);
        m_timer->start(100); // 100ms = 10Hz
    }

    void setGearPosition(const std::shared_ptr<CommonAPI::ClientId> _client,
                        std::string _gear,
                        setGearPositionReply_t _reply) override
    {
        qDebug() << "📞 [RPC] setGearPosition called:" << QString::fromStdString(_gear);
        
        QString gear = QString::fromStdString(_gear);
        if (gear != "P" && gear != "R" && gear != "N" && gear != "D") {
            qWarning() << "Invalid gear position:" << gear;
            _reply(false);
            return;
        }
        
        QString oldGear = m_currentGear;
        m_currentGear = gear;
        _reply(true);
        
        qDebug() << "✅ Gear position set to:" << gear;
        
        // Broadcast gear changed event
        if (oldGear != gear) {
            uint64_t timestamp = QDateTime::currentMSecsSinceEpoch();
            qDebug() << "📡 [Event] Broadcasting gearChanged:" << oldGear << "→" << gear;
            fireGearChangedEvent(gear.toStdString(), oldGear.toStdString(), timestamp);
        }
    }

private slots:
    void broadcastState() {
        uint64_t timestamp = QDateTime::currentMSecsSinceEpoch();
        fireVehicleStateChangedEvent(m_currentGear.toStdString(), m_currentSpeed, m_batteryLevel, timestamp);
        
        // Log every 1 second (10Hz → every 10 calls)
        static int count = 0;
        if (++count % 10 == 0) {
            qDebug() << "📡 [Event] vehicleStateChanged:"
                     << "Gear:" << m_currentGear
                     << "Speed:" << m_currentSpeed
                     << "Battery:" << m_batteryLevel << "%";
        }
    }

private:
    QString m_currentGear;
    uint16_t m_currentSpeed;
    uint8_t m_batteryLevel;
    QTimer* m_timer;
};

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName("VehicleControlECU_Mock");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "VehicleControlECU (Mock Version - PC Test)";
    qDebug() << "Service: VehicleControl (Mock Data)";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    qDebug() << "";
    qDebug() << "🌐 Initializing vsomeip service...";
    
    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    if (!runtime) {
        qCritical() << "❌ Failed to get CommonAPI Runtime!";
        return -1;
    }
    qDebug() << "✅ CommonAPI Runtime created";
    
    qDebug() << "";
    qDebug() << "📡 Registering VehicleControl service...";
    
    std::shared_ptr<MockVehicleControlStub> service = std::make_shared<MockVehicleControlStub>();
    
    const std::string domain = "local";
    const std::string instance = "v1.vehiclecontrol.VehicleControl";
    const std::string connection = "VehicleControlService";
    
    bool success = runtime->registerService(domain, instance, service, connection);
    
    if (!success) {
        qCritical() << "❌ Failed to register VehicleControl service!";
        return -1;
    }
    
    qDebug() << "✅ VehicleControl service registered";
    qDebug() << "   Domain:" << QString::fromStdString(domain);
    qDebug() << "   Instance:" << QString::fromStdString(instance);
    
    qDebug() << "";
    qDebug() << "🚀 VehicleControlECU Mock Service is now running!";
    qDebug() << "📡 Broadcasting vehicle state at 10Hz...";
    qDebug() << "   - Gear: N (default)";
    qDebug() << "   - Speed: 0 km/h (mock)";
    qDebug() << "   - Battery: 0% (mock)";
    qDebug() << "";
    qDebug() << "💡 Test gear change via GearApp to see events!";
    qDebug() << "═══════════════════════════════════════════════════════";
    
    return app.exec();
}

#include "main_mock.moc"
