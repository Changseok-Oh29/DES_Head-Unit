#include "gearmanager.h"
#include <QDebug>

GearManager::GearManager(QObject *parent)
    : QObject(parent)
    , m_gearPosition("P")  // 기본값: Park
{
    qDebug() << "GearManager initialized with position:" << m_gearPosition;
}

void GearManager::setGearPosition(const QString &position)
{
    // 같은 기어를 선택해도 항상 RPC 전송
    // 이유: ECU1-ECU2 상태 동기화 보장, 사용자 의도 확실히 반영
    qDebug() << "GearManager: Requesting gear change via vsomeip:" << m_gearPosition << "->" << position;
    
    // ═══════════════════════════════════════════════════════════
    // vsomeip RPC 호출: VehicleControlECU에 기어 변경 요청
    // ═══════════════════════════════════════════════════════════
    emit gearChangeRequested(position);
    
    // 참고: 실제 기어 변경은 VehicleControlECU의 응답(이벤트)을 받은 후 적용됨
    // VehicleControlClient::currentGearChanged → GearManager::setGearPosition으로
    // 다시 호출되어 m_gearPosition이 업데이트됨
}
