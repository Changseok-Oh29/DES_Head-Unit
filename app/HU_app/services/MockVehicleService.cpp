#include "MockVehicleService.h"
#include <QDebug>
#include <random>

MockVehicleService::MockVehicleService(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
    , m_currentGear(0)      // Park
    , m_batteryLevel(85)    // 85%
    , m_currentSpeed(0.0f)  // 정지
    , m_engineStatus(false) // 엔진 꺼짐
{
    initializeData();
    
    // 1초마다 시뮬레이션 업데이트
    connect(m_timer, &QTimer::timeout, this, &MockVehicleService::updateSimulation);
    m_timer->start(1000);
    
    qDebug() << "🚗 MockVehicleService 초기화 완료";
}

void MockVehicleService::setGear(int gear) {
    if (m_currentGear != gear) {
        m_currentGear = gear;
        emit gearChanged(m_currentGear);
        qDebug() << "⚙️ 기어 변경:" << gear;
    }
}

void MockVehicleService::setEngineStatus(bool status) {
    if (m_engineStatus != status) {
        m_engineStatus = status;
        emit engineStatusChanged(m_engineStatus);
        qDebug() << "🔧 엔진:" << (status ? "ON" : "OFF");
        
        if (!status) {
            // 엔진 꺼지면 속도 0
            m_currentSpeed = 0.0f;
            emit speedChanged(m_currentSpeed);
        }
    }
}

void MockVehicleService::emergencyStop() {
    qDebug() << "🚨 Emergency Stop!";
    
    setEngineStatus(false);
    setGear(0); // Park
    m_currentSpeed = 0.0f;
    emit speedChanged(m_currentSpeed);
}

void MockVehicleService::updateSimulation() {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    
    // 엔진이 켜져 있고 기어가 중성이 아니면 속도 시뮬레이션
    if (m_engineStatus && m_currentGear > 0) {
        std::uniform_real_distribution<> speedChange(-2.0, 5.0);
        float newSpeed = m_currentSpeed + speedChange(gen);
        newSpeed = std::max(0.0f, std::min(80.0f, newSpeed));
        
        if (abs(newSpeed - m_currentSpeed) > 0.1f) {
            m_currentSpeed = newSpeed;
            emit speedChanged(m_currentSpeed);
        }
    }
    
    // 배터리 소모 시뮬레이션 (10% 확률)
    if (m_engineStatus) {
        std::uniform_int_distribution<> batteryDrain(0, 9);
        if (batteryDrain(gen) == 0 && m_batteryLevel > 0) {
            m_batteryLevel--;
            emit batteryChanged(m_batteryLevel);
        }
    } else {
        // 엔진 꺼져있으면 배터리 회복 (5% 확률)
        std::uniform_int_distribution<> batteryRecover(0, 19);
        if (batteryRecover(gen) == 0 && m_batteryLevel < 100) {
            m_batteryLevel++;
            emit batteryChanged(m_batteryLevel);
        }
    }
}

void MockVehicleService::initializeData() {
    qDebug() << "📊 Mock 데이터 초기화";
    qDebug() << "⚙️ 기어:" << m_currentGear;
    qDebug() << "🔋 배터리:" << m_batteryLevel << "%";
    qDebug() << "🏃 속도:" << m_currentSpeed << "km/h";
    qDebug() << "🔧 엔진:" << (m_engineStatus ? "ON" : "OFF");
}
