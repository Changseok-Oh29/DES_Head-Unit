#include "gearmanager.h"
#include <QDebug>
#include <QHostAddress>
#include <QJsonDocument>

const QString GearManager::IC_ADDRESS = "127.0.0.1";

GearManager::GearManager(QObject *parent)
    : QObject(parent)
    , m_gearPosition("P")  // 기본값: Park
    , m_socket(new QUdpSocket(this))
{
    qDebug() << "GearManager initialized with position:" << m_gearPosition;
}

void GearManager::setGearPosition(const QString &position)
{
    if (m_gearPosition == position)
        return;
    
    qDebug() << "GearManager: [HU Internal] Gear position changed:" << m_gearPosition << "->" << position;
    m_gearPosition = position;
    emit gearPositionChanged(position);
    
    // ═══════════════════════════════════════════════════════════
    // HU → IC: Gear Change 송신
    // ═══════════════════════════════════════════════════════════
    // HU에서 기어가 변경되면 IC로 알림
    // QML에서 사용자가 기어 버튼 클릭 시 호출됨
    //
    // vsomeip 전환 시: sendGearChangeToIC()를 vsomeip send_event()로 교체
    // ═══════════════════════════════════════════════════════════
    sendGearChangeToIC(position);
}

void GearManager::onGearStatusReceivedFromIC(const QString &gear)
{
    // ═══════════════════════════════════════════════════════════
    // IC → HU: Gear Status 수신 처리
    // ═══════════════════════════════════════════════════════════
    // IpcManager로부터 IC의 gear status를 받아 HU 상태 동기화
    // IC와 HU의 기어 상태를 일치시킴
    //
    // 주의: 무한 루프 방지를 위해 IC로 다시 송신하지 않음
    // ═══════════════════════════════════════════════════════════
    
    if (m_gearPosition == gear) {
        qDebug() << "GearManager: [IC → HU] Gear already synchronized:" << gear;
        return;
    }
    
    qDebug() << "GearManager: [IC → HU] Synchronizing gear from IC:" << m_gearPosition << "->" << gear;
    m_gearPosition = gear;
    emit gearPositionChanged(gear);  // AmbientManager가 이 시그널을 받아 색상 변경
}

void GearManager::sendGearChangeToIC(const QString &gear)
{
    // ═══════════════════════════════════════════════════════════
    // UDP 통신: HU → IC (Gear Change)
    // ═══════════════════════════════════════════════════════════
    // 송신: HU (임시 포트) → IC (12345)
    // 프로토콜: UDP
    // 포맷: JSON
    //
    // vsomeip 전환 시:
    //   #ifdef USE_VSOMEIP
    //     m_vsomeipApp->send_event(GEAR_SERVICE_ID, GEAR_EVENT_ID, payload);
    //   #else
    //     // UDP fallback
    //   #endif
    // ═══════════════════════════════════════════════════════════
    
    QJsonObject message;
    message["type"] = "gear_change";
    message["gear"] = gear;
    message["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    
    QJsonDocument doc(message);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    
    m_socket->writeDatagram(data, QHostAddress(IC_ADDRESS), IC_PORT);
    qDebug() << "GearManager: [HU → IC] Sent gear change to IC:" << gear;
}
