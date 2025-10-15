# vsomeip 마이그레이션 가이드

## 현재 구조 (UDP 기반)
- **프로토콜**: UDP Socket
- **포맷**: JSON
- **포트**: HU(12346) ↔ IC(12345)
- **주소**: 127.0.0.1 (로컬)

## vsomeip 전환 시 변경 사항

### 1. 헤더 파일 (ipcmanager.h)

```cpp
#ifndef IPCMANAGER_H
#define IPCMANAGER_H

#include <QObject>
#include <QTimer>
#include <vsomeip/vsomeip.hpp>
#include <memory>

class IpcManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gearPosition READ gearPosition WRITE setGearPosition NOTIFY gearPositionChanged)
    Q_PROPERTY(bool ambientLightEnabled READ ambientLightEnabled WRITE setAmbientLightEnabled NOTIFY ambientLightEnabledChanged)
    Q_PROPERTY(QString ambientColor READ ambientColor WRITE setAmbientColor NOTIFY ambientColorChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)

public:
    explicit IpcManager(QObject *parent = nullptr);
    ~IpcManager();
    
    // 동일한 공개 인터페이스 유지
    QString gearPosition() const { return m_gearPosition; }
    bool ambientLightEnabled() const { return m_ambientLightEnabled; }
    QString ambientColor() const { return m_ambientColor; }
    bool isConnected() const { return m_isConnected; }

public slots:
    void setGearPosition(const QString &position);
    void setAmbientLightEnabled(bool enabled);
    void setAmbientColor(const QString &color);

signals:
    void gearPositionChanged();
    void ambientLightEnabledChanged();
    void ambientColorChanged();
    void connectionStateChanged();
    void speedDataReceived(int speed);
    void rpmDataReceived(int rpm);

private:
    // vsomeip 콜백
    void onMessage(const std::shared_ptr<vsomeip::message> &msg);
    void onAvailability(vsomeip::service_t service, vsomeip::instance_t instance, bool available);
    
    // 내부 메서드
    void sendVsomeipMessage(vsomeip::method_t method, const std::vector<uint8_t> &payload);
    void processVsomeipMessage(const std::shared_ptr<vsomeip::message> &msg);
    
    // 멤버 변수
    QString m_gearPosition;
    bool m_ambientLightEnabled;
    QString m_ambientColor;
    bool m_isConnected;
    
    // vsomeip 관련
    std::shared_ptr<vsomeip::application> m_app;
    
    // SOME/IP 서비스 정의
    static constexpr vsomeip::service_t SERVICE_ID = 0x1234;
    static constexpr vsomeip::instance_t INSTANCE_ID = 0x5678;
    static constexpr vsomeip::method_t METHOD_GEAR_CHANGE = 0x0001;
    static constexpr vsomeip::method_t METHOD_AMBIENT_LIGHT = 0x0002;
    static constexpr vsomeip::event_t EVENT_SPEED = 0x8001;
    static constexpr vsomeip::event_t EVENT_RPM = 0x8002;
};

#endif // IPCMANAGER_H
```

### 2. 구현 파일 (ipcmanager.cpp)

```cpp
#include "ipcmanager.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

IpcManager::IpcManager(QObject *parent)
    : QObject(parent)
    , m_gearPosition("P")
    , m_ambientLightEnabled(true)
    , m_ambientColor("#3498db")
    , m_isConnected(false)
{
    // vsomeip 애플리케이션 초기화
    m_app = vsomeip::runtime::get()->create_application("HeadUnitApp");
    
    if (!m_app->init()) {
        qDebug() << "IpcManager: Failed to initialize vsomeip application";
        return;
    }
    
    // 메시지 핸들러 등록
    m_app->register_message_handler(
        SERVICE_ID, 
        INSTANCE_ID, 
        vsomeip::ANY_METHOD,
        [this](const std::shared_ptr<vsomeip::message> &msg) {
            onMessage(msg);
        }
    );
    
    // 서비스 가용성 핸들러
    m_app->register_availability_handler(
        SERVICE_ID,
        INSTANCE_ID,
        [this](vsomeip::service_t service, vsomeip::instance_t instance, bool available) {
            onAvailability(service, instance, available);
        }
    );
    
    // 서비스 요청
    m_app->request_service(SERVICE_ID, INSTANCE_ID);
    
    // 이벤트 구독 (속도, RPM 데이터)
    std::set<vsomeip::eventgroup_t> eventgroups;
    eventgroups.insert(0x0001);
    m_app->request_event(SERVICE_ID, INSTANCE_ID, EVENT_SPEED, eventgroups);
    m_app->request_event(SERVICE_ID, INSTANCE_ID, EVENT_RPM, eventgroups);
    m_app->subscribe(SERVICE_ID, INSTANCE_ID, 0x0001);
    
    // vsomeip 앱 시작
    m_app->start();
    
    qDebug() << "IpcManager: vsomeip initialized";
}

IpcManager::~IpcManager()
{
    if (m_app) {
        m_app->stop();
    }
}

void IpcManager::setGearPosition(const QString &position)
{
    if (m_gearPosition != position) {
        m_gearPosition = position;
        emit gearPositionChanged();
        
        // JSON 페이로드 생성
        QJsonObject json;
        json["gear"] = position;
        json["timestamp"] = QDateTime::currentMSecsSinceEpoch();
        
        QJsonDocument doc(json);
        QByteArray data = doc.toJson(QJsonDocument::Compact);
        
        // vsomeip 메시지 전송
        std::vector<uint8_t> payload(data.begin(), data.end());
        sendVsomeipMessage(METHOD_GEAR_CHANGE, payload);
        
        qDebug() << "IpcManager: Gear changed to" << position;
    }
}

void IpcManager::setAmbientColor(const QString &color)
{
    if (m_ambientColor != color) {
        m_ambientColor = color;
        emit ambientColorChanged();
        
        if (m_ambientLightEnabled) {
            QJsonObject json;
            json["enabled"] = true;
            json["color"] = color;
            json["timestamp"] = QDateTime::currentMSecsSinceEpoch();
            
            QJsonDocument doc(json);
            QByteArray data = doc.toJson(QJsonDocument::Compact);
            
            std::vector<uint8_t> payload(data.begin(), data.end());
            sendVsomeipMessage(METHOD_AMBIENT_LIGHT, payload);
        }
        
        qDebug() << "IpcManager: Ambient color changed to" << color;
    }
}

void IpcManager::sendVsomeipMessage(vsomeip::method_t method, const std::vector<uint8_t> &payload)
{
    auto request = vsomeip::runtime::get()->create_request();
    request->set_service(SERVICE_ID);
    request->set_instance(INSTANCE_ID);
    request->set_method(method);
    request->set_interface_version(0x01);
    
    std::shared_ptr<vsomeip::payload> pl = vsomeip::runtime::get()->create_payload();
    pl->set_data(payload);
    request->set_payload(pl);
    
    m_app->send(request);
}

void IpcManager::onMessage(const std::shared_ptr<vsomeip::message> &msg)
{
    // vsomeip 메시지 처리
    if (msg->get_message_type() == vsomeip::message_type_e::MT_NOTIFICATION) {
        // 이벤트 (속도, RPM)
        auto payload = msg->get_payload();
        std::vector<uint8_t> data(payload->get_data(), 
                                  payload->get_data() + payload->get_length());
        
        QByteArray qdata(reinterpret_cast<const char*>(data.data()), data.size());
        QJsonDocument doc = QJsonDocument::fromJson(qdata);
        QJsonObject json = doc.object();
        
        if (msg->get_method() == EVENT_SPEED) {
            int speed = json["speed"].toInt();
            emit speedDataReceived(speed);
        } else if (msg->get_method() == EVENT_RPM) {
            int rpm = json["rpm"].toInt();
            emit rpmDataReceived(rpm);
        }
    }
}

void IpcManager::onAvailability(vsomeip::service_t service, 
                                 vsomeip::instance_t instance, 
                                 bool available)
{
    m_isConnected = available;
    emit connectionStateChanged();
    qDebug() << "IpcManager: Service" << std::hex << service 
             << "is" << (available ? "available" : "unavailable");
}
```

### 3. vsomeip 설정 파일 (vsomeip-config.json)

```json
{
    "unicast" : "127.0.0.1",
    "logging" :
    {
        "level" : "info",
        "console" : "true",
        "file" : { "enable" : "false" }
    },
    "applications" :
    [
        {
            "name" : "HeadUnitApp",
            "id" : "0x1111"
        }
    ],
    "services" :
    [
        {
            "service" : "0x1234",
            "instance" : "0x5678",
            "unreliable" : "30509"
        }
    ],
    "routing" : "HeadUnitApp",
    "service-discovery" :
    {
        "enable" : "true",
        "multicast" : "224.0.0.1",
        "port" : "30490",
        "protocol" : "udp"
    }
}
```

### 4. CMakeLists.txt 수정

```cmake
find_package(vsomeip3 REQUIRED)

target_link_libraries(HU_app
    PRIVATE 
    Qt${QT_VERSION_MAJOR}::Core 
    Qt${QT_VERSION_MAJOR}::Quick 
    Qt${QT_VERSION_MAJOR}::Multimedia 
    Qt${QT_VERSION_MAJOR}::Network
    vsomeip3
)
```

## 장점

1. **표준 프로토콜**: AUTOSAR SOME/IP 표준 준수
2. **서비스 디스커버리**: 자동 서비스 검색
3. **QoS 지원**: Quality of Service 보장
4. **확장성**: 다중 ECU 통신 용이
5. **보안**: TLS/SSL 지원 가능

## QML 코드 변경 불필요

QML 코드는 **전혀 변경할 필요 없음**:
```qml
// 동일하게 사용 가능
ipcManager.gearPosition = "D"
ipcManager.ambientColor = "#ff0000"
```

## 마이그레이션 단계

1. ✅ vsomeip 라이브러리 설치
2. ✅ IpcManager 내부 구현 변경
3. ✅ 설정 파일 추가
4. ✅ 테스트 및 검증
5. ✅ QML 인터페이스는 그대로 유지

이렇게 하면 **UI 계층(QML)과 통신 계층(IpcManager)이 분리**되어 있어서, 통신 프로토콜만 교체 가능합니다!
