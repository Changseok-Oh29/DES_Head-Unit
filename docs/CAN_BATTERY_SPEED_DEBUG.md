# CAN 통신 및 배터리/속도 디버깅 가이드

## 문제 상황
- ✅ **배터리 값**: 정상적으로 받아옴 (INA219 작동)
- ❌ **스피드 값**: 제대로 못받아옴

## 1단계: CAN 인터페이스 확인

```bash
# CAN 인터페이스 목록
ip link show

# CAN0 상태 확인
ip link show can0

# 예상 출력 (정상):
# can0: <NOARP,UP,LOWER_UP,ECHO> mtu 16 qdisc pfifo_fast state UP mode DEFAULT group default qlen 10
#     link/can

# 예상 출력 (비정상):
# can0: <NOARP> mtu 16 qdisc noop state DOWN mode DEFAULT group default qlen 10

# CAN 인터페이스 활성화 (DOWN 상태일 경우)
ip link set can0 up type can bitrate 500000
```

## 2단계: CAN 메시지 모니터링

### 실시간 CAN 메시지 확인

```bash
# can-utils 설치 확인
which candump cansend

# CAN 메시지 실시간 덤프
candump can0

# 예상 출력 (정상):
# can0  123   [8]  01 02 03 04 05 06 07 08
# can0  456   [4]  AA BB CC DD

# 스피드 관련 ID 필터링 (예: 0x123)
candump can0,123:7FF

# 타임스탬프 포함
candump can0 -t a

# 로그 파일 저장
candump can0 -l
```

### CAN 메시지 전송 테스트

```bash
# 테스트 메시지 전송
cansend can0 123#DEADBEEF

# 스피드 시뮬레이션 (예: 30 km/h = 0x1E)
cansend can0 123#1E00000000000000
```

## 3단계: 스피드 데이터 소스 확인

### VehicleControlECU가 스피드를 어디서 받아오는가?

**가능성 A: CAN 버스에서 직접 수신**
```cpp
// VehicleControlECU/src/SpeedMonitor.cpp
// CAN 메시지 ID 확인
// 예: 0x123 -> 스피드 정보
```

**가능성 B: 게임패드 throttle 값 기반 계산**
```cpp
// throttle * max_speed = current_speed
// throttle이 0이면 speed도 0
```

**가능성 C: 모터 PWM 피드백**
```cpp
// PCA9685 PWM duty cycle 읽기
// PWM 값 -> 속도 변환
```

## 4단계: 배터리 vs 스피드 차이점 분석

### 배터리 (INA219) - I2C 통신

```bash
# I2C 디바이스 스캔
i2cdetect -y 1

# 예상 출력:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 00:          -- -- -- -- -- -- -- -- -- -- -- -- --
# 10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 30: -- -- -- -- -- -- -- -- -- -- -- -- 3c -- -- --
# 40: 40 41 -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 60: 60 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 70: -- -- -- -- -- -- -- 77

# 0x40: PCA9685 (스티어링)
# 0x41: INA219 (배터리 모니터)
# 0x60: PCA9685 (스로틀)
# 0x3c: SSD1306 (디스플레이)

# INA219 레지스터 직접 읽기
i2cget -y 1 0x41 0x02 w  # Bus Voltage
i2cget -y 1 0x41 0x04 w  # Current
```

### 스피드 - CAN 통신 (추정)

```bash
# CAN 통계
ip -s -d link show can0

# 예상 출력:
# RX: bytes  packets  errors  dropped overrun mcast
#     12345   678      0       0       0       0
# TX: bytes  packets  errors  dropped carrier collsns
#     5678    234      0       0       0       0

# RX/TX가 0이면 CAN 통신 문제
```

## 5단계: 코드 레벨 디버깅

### BatteryMonitor.cpp 확인 (정상 작동)

```cpp
// app/VehicleControlECU/src/BatteryMonitor.cpp

float BatteryMonitor::getVoltage()
{
    if (!m_ina219) return 0.0f;
    
    try {
        float busVoltage = m_ina219->getBusVoltage();
        float shuntVoltage = m_ina219->getShuntVoltage();
        return busVoltage + shuntVoltage / 1000.0f;  // ✅ 작동
    } catch (const std::exception& e) {
        qWarning() << "Failed to read battery voltage:" << e.what();
        return 0.0f;
    }
}
```

### SpeedMonitor.cpp 확인 (문제 가능성)

```bash
# 스피드 모니터 코드 확인
find /home/seame/HU/DES_Head-Unit/app/VehicleControlECU -name "*Speed*" -o -name "*speed*"
grep -r "speed" app/VehicleControlECU/src/
```

**예상 문제점:**

1. **CAN 수신 코드 없음**
   ```cpp
   // Missing: CAN socket read() code
   ```

2. **Throttle 값이 0**
   ```cpp
   // GamepadHandler에서 throttle 값이 안옴
   // throttle = 0 → speed = 0
   ```

3. **속도 계산 로직 오류**
   ```cpp
   // PWM → RPM → km/h 변환 실패
   ```

## 6단계: 로그 기반 진단

### VehicleControlECU 로그에서 확인할 항목

```bash
journalctl -u vehiclecontrol-ecu --since "10 minutes ago" | grep -E "battery|speed|throttle|CAN"
```

**정상 로그 예시:**
```
Battery: 12.3V, 450mA, 5.5W
Throttle: 0.5 → Speed: 15 km/h
CAN RX: ID=0x123, Data=[1E 00 00 00 00 00 00 00]
```

**비정상 로그 예시:**
```
Battery: 12.3V, 450mA, 5.5W  ✅
Throttle: 0.0                 ❌ (게임패드 문제)
Speed: 0.0 km/h               ❌
CAN: No messages              ❌ (CAN 통신 없음)
```

## 7단계: 근본 원인 추정

### 시나리오 A: 게임패드 입력 문제
```
게임패드 ❌ → throttle = 0 → 모터 안돔 → speed = 0
```

**해결:**
1. 게임패드 디버깅 가이드 참고
2. `evtest /dev/input/js0` 확인
3. GamepadHandler 로그 확인

### 시나리오 B: CAN 통신 문제
```
CAN 버스 ❌ → 스피드 데이터 수신 안됨 → speed = 0
```

**해결:**
1. `ip link show can0` 확인
2. `candump can0` 확인
3. CAN 드라이버 로드 확인: `lsmod | grep can`

### 시나리오 C: 스피드 계산 로직 없음
```
Throttle 입력 ✅ → 모터 작동 ✅ → 하지만 스피드 계산 코드 ❌
```

**해결:**
1. SpeedMonitor 구현 확인
2. Throttle → Speed 변환 로직 추가

## 8단계: 선배 기수 참고

### Team2 & Team4 방식

**배터리:**
```python
# piracer/vehicles.py
def get_battery_voltage(self) -> float:
    return self.battery_monitor.bus_voltage + self.battery_monitor.shunt_voltage
    # ✅ I2C 직접 읽기
```

**스피드:**
```python
# 선배들은 스피드를 직접 계산하지 않음!
# 대신 throttle 값을 모터에 직접 전달

def set_throttle_percent(self, value: float) -> None:
    # PWM 값 설정만 함
    # 속도 피드백 없음
```

**결론: 선배들도 실제 스피드를 측정하지 않음!**
- Throttle 입력만 있음
- 실제 속도는 **Encoder나 CAN에서 받아와야 함**

## 9단계: 해결 방안

### Option 1: 스피드 = Throttle * 최대속도 (간단)

```cpp
// VehicleControlECU/src/SpeedMonitor.cpp
float SpeedMonitor::getSpeed()
{
    const float MAX_SPEED_KMH = 30.0f;  // PiRacer 최대 속도
    float throttle = m_currentThrottle;  // GamepadHandler에서 받은 값
    return throttle * MAX_SPEED_KMH;
}
```

### Option 2: CAN 버스에서 수신 (정확)

```cpp
// CAN 소켓 설정
int can_socket = socket(PF_CAN, SOCK_RAW, CAN_RAW);

// CAN 메시지 읽기
struct can_frame frame;
read(can_socket, &frame, sizeof(frame));

// 스피드 ID 확인 (예: 0x123)
if (frame.can_id == 0x123) {
    uint8_t speed_raw = frame.data[0];
    float speed_kmh = speed_raw;  // 변환 로직
}
```

### Option 3: 모터 Encoder 추가 (하드웨어)

```
PiRacer에 홀 센서 또는 Encoder 추가
→ PWM 신호와 별개로 실제 RPM 측정
→ RPM → km/h 변환
```

## 10단계: 즉시 테스트 가능한 명령어

```bash
# Raspberry Pi SSH 접속 후:

# 1. I2C 확인
i2cdetect -y 1

# 2. 배터리 값 직접 읽기
i2cget -y 1 0x41 0x02 w

# 3. CAN 인터페이스 확인
ip link show can0

# 4. CAN 메시지 확인 (30초)
timeout 30 candump can0

# 5. 게임패드 확인
evtest /dev/input/js0

# 6. VehicleControlECU 로그
journalctl -u vehiclecontrol-ecu -f
```

## 결론

**배터리는 I2C로 직접 읽어서 정상 작동**
**스피드는 다음 중 하나:**
1. 게임패드 입력 문제 → Throttle = 0
2. CAN 통신 미구현 → 실제 속도 데이터 없음
3. 스피드 계산 로직 없음 → Throttle 값만 있고 변환 안함

**우선순위:**
1. 게임패드 작동 확인 (evtest)
2. Throttle 값 로그 확인
3. 스피드 = Throttle * 30 (임시)
4. CAN 통신 구현 (정확한 속도)
