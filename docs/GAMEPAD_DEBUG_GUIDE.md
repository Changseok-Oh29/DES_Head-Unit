# Gamepad 디버깅 가이드

## 1단계: Raspberry Pi에서 Bluetooth 및 Joystick 확인

```bash
# SSH 접속
ssh root@<raspberry-pi-ip>

# Bluetooth 서비스 확인
systemctl status bluetooth
# 예상: active (running)

# Bluetooth 컨트롤러 확인
hciconfig -a
# 예상: hci0 UP RUNNING

# 게임패드 페어링 상태 확인
bluetoothctl
[bluetooth]# devices
# 게임패드 MAC 주소가 보여야 함
[bluetooth]# info XX:XX:XX:XX:XX:XX
# Connected: yes가 보여야 함

# Joystick 디바이스 확인
ls -l /dev/input/js0
# 예상: crw-rw---- 1 root input 13, 0

# Joystick 이벤트 실시간 확인
evtest /dev/input/js0
# 버튼/조이스틱 조작 시 이벤트 출력 확인
```

## 2단계: VehicleControlECU 서비스 로그 확인

```bash
# 서비스 상태
systemctl status vehiclecontrol-ecu

# 실시간 로그 확인
journalctl -u vehiclecontrol-ecu -f

# 최근 로그 100줄
journalctl -u vehiclecontrol-ecu -n 100 --no-pager

# 게임패드 초기화 메시지 확인
journalctl -u vehiclecontrol-ecu | grep -i "gamepad\|joystick"

# 예상 로그:
# "✅ GamepadHandler initialized"
# "Gamepad connected: /dev/input/js0"
```

## 3단계: 게임패드 입력 테스트

### 방법 A: jstest 사용 (권장)

```bash
# jstest 설치 (빌드 시 추가 필요)
apt-get install joystick

# 테스트 실행
jstest /dev/input/js0

# 버튼과 축 조작 시 값 변화 확인
# Axes:  0:     0  1:     0  2:     0  3:     0
# Buttons:  0:off  1:off  2:off  3:off ...
```

### 방법 B: 간단한 Python 테스트 스크립트

```python
#!/usr/bin/env python3
import struct
import array
import os

dev_fn = '/dev/input/js0'

print(f"Opening {dev_fn}...")
jsdev = open(dev_fn, 'rb')

print("Reading events... (Press Ctrl+C to stop)")
while True:
    evbuf = jsdev.read(8)
    if evbuf:
        time, value, typev, number = struct.unpack('IhBB', evbuf)
        
        if typev & 0x01:  # Button
            print(f"Button {number}: {'ON' if value else 'OFF'}")
        
        if typev & 0x02:  # Axis
            axis_val = value / 32767.0
            print(f"Axis {number}: {axis_val:.2f}")
```

저장: `/tmp/test_gamepad.py`
실행: `python3 /tmp/test_gamepad.py`

## 4단계: C++ 코드 디버깅

### GamepadHandler 로그 추가 확인

`/app/VehicleControlECU/src/GamepadHandler.cpp`에 다음 로그가 출력되는지 확인:

```cpp
qDebug() << "✅ GamepadHandler initialized";
qDebug() << "Gamepad event - Buttons:" << ... << "Axes:" << ...;
qDebug() << "Steering:" << steering << "Throttle:" << throttle;
```

### 예상 문제점:

1. **파일 열기 실패**: `/dev/input/js0` 권한 문제
2. **이벤트 읽기 실패**: `read()` 타임아웃 또는 블로킹
3. **값 파싱 오류**: 구조체 언패킹 문제
4. **Qt Signal 미전달**: Signal/Slot 연결 문제

## 5단계: 권한 확인

```bash
# /dev/input/js0 권한 확인
ls -l /dev/input/js0
# 예상: crw-rw---- 1 root input 13, 0

# vehiclecontrol-ecu 사용자 확인
ps aux | grep vehiclecontrol-ecu

# input 그룹에 root 추가 (필요시)
usermod -aG input root

# 서비스 재시작
systemctl restart vehiclecontrol-ecu
```

## 6단계: 선배 기수 방식 비교

### Team2 & Team4 공통점:
- **Python** + `piracer` 라이브러리 사용
- `ShanWanGamepad` 클래스 직접 활용
- `/dev/input/js0` 직접 읽기

### 우리 방식:
- **C++** + 직접 구현
- Qt 기반 GamepadHandler

### 권장 사항:

**Option 1: Python 게임패드 래퍼 사용** (빠른 해결)
- Python으로 게임패드 읽기
- Socket으로 C++에 전달

**Option 2: C++ 코드 개선** (근본적 해결)
- 선배들의 Python 코드를 C++로 정확히 포팅
- ioctl 코드 추가 (버튼/축 매핑)

## 7단계: 배터리 vs 스피드 문제 격리

### 배터리 값 정상 확인:

```bash
# I2C 디바이스 확인
i2cdetect -y 1

# 예상 출력:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 00:          -- -- -- -- -- -- -- -- -- -- -- -- --
# ...
# 40: -- 41 -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 41: INA219 (배터리 모니터)

# INA219 직접 테스트 (Python)
python3 << EOF
import busio
from board import SCL, SDA
from adafruit_ina219 import INA219

i2c_bus = busio.I2C(SCL, SDA)
ina = INA219(i2c_bus, addr=0x41)

print(f"Bus Voltage: {ina.bus_voltage}V")
print(f"Shunt Voltage: {ina.shunt_voltage}mV")
print(f"Current: {ina.current}mA")
print(f"Power: {ina.power}W")
EOF
```

### 스피드 값이 안나오는 이유:

**가능성 1: CAN 통신 문제**
```bash
# CAN 인터페이스 확인
ip link show can0

# CAN 메시지 확인
candump can0

# 예상: 스피드 관련 CAN ID가 안보임
```

**가능성 2: 게임패드 입력이 안되서 throttle이 0**
```bash
# VehicleControlECU 로그에서 throttle 값 확인
journalctl -u vehiclecontrol-ecu | grep throttle

# 예상: throttle 값이 항상 0.0
```

**가능성 3: Motor Driver 문제**
```bash
# I2C 디바이스에서 PCA9685 확인
i2cdetect -y 1

# 예상 출력:
# 40: 40 41 -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 60 --
# 40: PCA9685 (스티어링)
# 60: PCA9685 (스로틀)
```

## 해결 우선순위

1. **게임패드 이벤트 읽기 확인** (evtest, jstest)
2. **VehicleControlECU 로그 확인** (게임패드 초기화 여부)
3. **권한 문제 해결** (input 그룹)
4. **C++ 코드 로깅 강화** (디버그 출력)
5. **선배 방식 참고** (Python 래퍼 고려)
