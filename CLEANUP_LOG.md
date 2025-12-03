# 프로젝트 정리 로그

**작성일:** 2025년 12월 3일  
**목적:** 불필요한 파일/디렉토리 정리 및 문서 통합

---

## ✅ 삭제 완료 항목

### Phase 1: 안전 삭제 (2025-12-03)

#### 1. 중복 레시피 파일
```bash
✅ /home/seame/DES_Head-Unit/app/VehicleControlECU/recipes-commonapi/
✅ /home/seame/DES_Head-Unit/app/VehicleControlECU/recipes-vsomeip/
✅ /home/seame/DES_Head-Unit/app/VehicleControlECU/vehiclecontrol-ecu_1.0.bb
```
**이유:** meta-vehiclecontrol에 동일 레시피 존재

#### 2. 백업 파일
```bash
✅ /home/seame/DES_Head-Unit/app/HU_MainApp/backup_old_version/
✅ /home/seame/DES_Head-Unit/meta/meta-vehiclecontrol/CHANGELOG.md.old
```
**이유:** Git 히스토리에 보관됨

#### 3. 임시 파일
```bash
✅ /home/seame/DES_Head-Unit/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
```
**이유:** 일회성 디버깅용

#### 4. 튜토리얼 디렉토리
```bash
✅ /home/seame/DES_Head-Unit/commonapi/hello_world_tutorial/
✅ /home/seame/DES_Head-Unit/commonapi/simple/
```
**이유:** 학습용, 실제 사용 안 함

### Phase 2: 추가 삭제 (2025-12-03)

#### 5. 빌드 아티팩트
```bash
✅ /home/seame/DES_Head-Unit/src-gen/
```
**크기:** 92KB  
**이유:** 이전 CommonAPI 코드 생성 결과물, 현재는 `commonapi/generated/` 사용

#### 6. CAN 과거 문서 (MCP2515 시절)
```bash
✅ /home/seame/DES_Head-Unit/docs/CAN_BATTERY_SPEED_DEBUG.md
✅ /home/seame/DES_Head-Unit/docs/CAN_TROUBLESHOOTING_20251112.md
✅ /home/seame/DES_Head-Unit/docs/YOCTO_CAN_GAMEPAD_FIX.md
```
**이유:** MCP2518FD로 해결 완료, `CAN_MCP2518FD_DEPLOYMENT_SUCCESS.md`가 최신 문서

---

## 🔍 판단 결과

### ❌ 삭제하지 않음 (필요)

#### 1. `.vscode/` 디렉토리
```bash
❌ 삭제 안 함: /home/seame/DES_Head-Unit/.vscode/
```
**내용:**
- `settings.json`: VS Code 프로젝트 설정 (cmake.sourceDirectory, file associations)

**판단:** 
- ⚠️ **삭제 가능하지만 권장하지 않음**
- VS Code 사용자에게 유용 (CMake 경로, 파일 연결 설정)
- 용량: 매우 작음 (~1KB)
- `.gitignore`에 추가하여 개인 설정으로 관리 권장

**권장 조치:**
```bash
# .gitignore에 추가
echo ".vscode/" >> /home/seame/DES_Head-Unit/.gitignore
```

#### 2. VehicleControlECU 문서
```bash
❌ 삭제 안 함: /home/seame/DES_Head-Unit/app/VehicleControlECU/YOCTO_BUILD_INFO.md
❌ 삭제 안 함: /home/seame/DES_Head-Unit/app/VehicleControlECU/YOCTO_LAYER_GUIDE.md
```
**판단:**
- **보존 필요** ✅
- `YOCTO_BUILD_INFO.md`: 의존성, 패키지, 설치 경로 등 빌드 정보
- `YOCTO_LAYER_GUIDE.md`: Yocto 레이어 구조 가이드

**이유:**
- `meta-vehiclecontrol`의 레시피 작성 시 참고 문서
- Yocto 빌드 환경 복구 시 필요한 정보
- 중복 아님 (meta-vehiclecontrol 문서는 빌드 절차, 이 문서는 의존성/구조)

**개선 제안:**
- 위치는 적절함 (애플리케이션 디렉토리 내)
- 또는 `meta/meta-vehiclecontrol/docs/app-reference/`로 이동 고려

---

## 📝 CommonAPI 설정 파일 분석

### AmbientApp의 두 개 설정 파일

#### 1. `commonapi_ambient.ini` (실제 사용 중) ✅
```ini
[logging]
console = true
level = info

[default]
binding = someip
default-folder = /usr/local/lib/commonapi
```
**사용처:** `run.sh`에서 `COMMONAPI_CONFIG` 환경변수로 설정  
**목적:** 배포 환경용 (라이브러리 경로: `/usr/local`)

#### 2. `commonapi.ini` (개발 환경용) ⚠️
```ini
[core]
libpath=/home/seam/DES_Head-Unit/install_folder/lib

[someip]
config=/home/seam/DES_Head-Unit/app/AmbientApp/vsomeip.json
```
**사용처:** 직접 사용 안 됨  
**목적:** 로컬 개발/테스트용 (절대 경로 포함)

#### 판단: 둘 다 보존 ✅

**이유:**
- `commonapi_ambient.ini`: 실제 배포/실행 시 사용
- `commonapi.ini`: 개발자가 로컬 환경에서 테스트할 때 유용
- 병존 가능 (용량 작음, 혼동 위험 낮음)

**개선 제안:**
```bash
# 명확한 네이밍으로 변경 (선택)
commonapi.ini → commonapi.dev.ini
commonapi_ambient.ini → commonapi.prod.ini
```

---

## 🎯 Manager 파일 필요성

### 각 앱의 Manager 클래스

#### 1. `AmbientManager` (AmbientApp)
```cpp
class AmbientManager : QObject
- setAmbientLightEnabled(bool)
- setAmbientColor(QString)
- setBrightness(qreal)  // MediaApp 볼륨과 연동
```
**역할:** 
- QML ↔ C++ 데이터 바인딩
- HU 내부 통신 (MediaControlClient → AmbientManager)
- 비즈니스 로직 (밝기, 색상 관리)

**판단:** **필수** ✅  
**이유:** vsomeip 클라이언트와 QML을 연결하는 컨트롤러 역할

#### 2. `GearManager` (GearApp)
```cpp
class GearManager : QObject
- setGearPosition(QString)
- emit gearChangeRequested(QString)
```
**역할:**
- QML 기어 버튼 → vsomeip RPC 호출
- VehicleControlClient와 QML 중재

**판단:** **필수** ✅  
**이유:** MVC 패턴의 Model 역할, UI와 통신 로직 분리

#### 3. `MediaManager` (MediaApp)
```cpp
class MediaManager : QObject
- 미디어 재생, 볼륨 제어
- vsomeip 이벤트 발행
```
**판단:** **필수** ✅  
**이유:** 비즈니스 로직 + vsomeip 서비스 제공

### 결론: 모든 Manager 파일 필요 ✅

**아키텍처:**
```
QML (View)
   ↕
Manager (Controller/Model)
   ↕
vsomeip Client/Service (Network)
```

Manager가 없으면:
- ❌ QML에서 직접 vsomeip 호출 → 결합도 증가
- ❌ 비즈니스 로직 분산 → 유지보수 어려움
- ❌ 테스트 불가능 (QML과 네트워크가 강결합)

---

## 📚 vsomeip 문서 통합 계획

### ✅ 완료: 통합 문서 생성 (2025-01-15)

**생성된 파일:**
- `docs/VSOMEIP_RASPIOS_IMPLEMENTATION_GUIDE.md` (완전한 vsomeip 구현 가이드)

**통합된 내용:**
```
Part 1: Routing Manager 아키텍처
- 1.1 vsomeip 핵심 개념 (3대 원칙)
- 1.2 routingmanagerd 독립 방식 + 문제 해결
- 1.3 Central RM 방식 (VehicleControlECU as RM)
- 1.4 Hybrid 방식 (실제 채택 아키텍처)

Part 2: 네트워크 설정
- 2.1 하드웨어 연결 (직접 연결)
- 2.2 Ethernet IP 설정 (임시/NetworkManager/dhcpcd)
- 2.3 멀티캐스트 라우팅 (224.0.0.0/4)
- 2.4 Service Discovery 설정 (netmask 필수!)

Part 3: 디버깅 가이드
- 3.1 7대 주요 오류 해결
  • "Couldn't connect to /tmp/vsomeip-0"
  • "other routing manager present"
  • Service Discovery 실패
  • 방화벽 차단 등
- 3.2 디버깅 명령어 (tcpdump, ip route, ps)
- 3.3 로그 분석 (정상/에러 패턴)

Part 4: 실전 운용
- 4.1 부팅부터 통신까지 절차 (6단계)
- 4.2 자동화 스크립트
  • setup_network.sh (네트워크 자동 설정)
  • cleanup_vsomeip.sh (프로세스 정리)
  • start_all_ecu2.sh (앱 일괄 시작)
  • diagnose_vsomeip.sh (빠른 진단)
- 4.3 트러블슈팅 체크리스트
- 4.4 성능 최적화 (SD 타이밍, 로그 레벨)
```

### ✅ 아카이브된 기존 문서 (8개)

**이동 위치:** `docs/archive/vsomeip-tests/`

```
전체통신테스트.md (40KB)
├─ 초기 multi-ECU 통신 테스트 전 과정
├─ routingmanagerd 방식 최초 시도
└─ 다양한 vsomeip.json 설정 실험

기어-Vehicle앱통신.md (41KB)
├─ GearApp ↔ VehicleControlECU 통신 구현
├─ NetworkManager vs dhcpcd 비교
└─ QML UI 연동 과정

통신테스트_라우팅_SD.md (13KB)
└─ Routing + Service Discovery 집중 테스트

ECU2_DEPLOYMENT_ROUTING_MANAGER.md (11KB)
└─ ECU2에 routingmanagerd 배포 가이드

ROUTING_MANAGER_MIGRATION_COMPLETE.md (6.4KB)
└─ Central RM → Hybrid RM 마이그레이션 기록

ECU_BOOT_TO_COMMUNICATION_GUIDE.md (14KB)
├─ 부팅부터 통신까지 단계별 절차
└─ cleanup 스크립트 예시

ECU_COMMUNICATION_TROUBLESHOOTING_GUIDE.md (21KB)
├─ 7대 주요 에러 상세 분석
└─ 각 에러별 원인/해결책

DEPLOYMENT_GUIDE.md (15KB)
└─ 전체 배포 절차 (초기 버전)

총: 161.4KB (참고용 아카이브)
```

### 통합 효과

**Before:**
- 8개 문서에 내용 분산
- 중복 설명 다수 (네트워크 설정 3곳, RM 설정 4곳)
- 최신/정확한 정보 불명확

**After:**
- ✅ 1개 통합 가이드 (권위 있는 단일 소스)
- ✅ 실제 겪은 문제 + 해결책 중심 재구성
- ✅ 실행 가능한 명령어/스크립트 포함
- ✅ 4단계 구조 (아키텍처 → 네트워크 → 디버깅 → 실전)
- ✅ 빠른 검색/참조 가능

**보존 이유 (아카이브):**
- 초기 개발 과정의 상세 기록 (시행착오 히스토리)
- 다양한 시도와 실패 사례 (학습 자료)
- 특정 에러 메시지의 원본 로그 보존

---

## 정리 요약

### 삭제된 항목 (총 ~1.5MB)

**Phase 1 삭제:**
- app/VehicleControlECU/recipes-* (중복 레시피)
- app/HU_MainApp/backup_old_version/ (백업)
- commonapi/hello_world_tutorial/ (튜토리얼)
- libssl1.1 deb 파일

**Phase 2 삭제:**
- src-gen/ (92KB, 자동 생성 파일)
- docs/CAN_BATTERY_SPEED_DEBUG.md
- docs/CAN_TROUBLESHOOTING_20251112.md
- docs/YOCTO_CAN_GAMEPAD_FIX.md

### 보존된 항목

**사용자 요청 보존:**
- HelloWorld/ - 학습 자료
- install_folder/ - 라이브러리
- HU 앱들 (AmbientApp, GearApp, MediaApp, IC_app, HU_MainApp) - 팀 merge 대기

**판단 후 보존:**
- .vscode/ - VS Code 설정 (gitignore 권장)
- YOCTO_BUILD_INFO.md, YOCTO_LAYER_GUIDE.md - 빌드 참고 문서
- commonapi_ambient.ini, commonapi.ini - 각각 프로덕션/개발용
- Manager 클래스들 - MVC 패턴 핵심

### 통합/아카이브된 문서

**새 통합 문서:**
- `docs/VSOMEIP_RASPIOS_IMPLEMENTATION_GUIDE.md` ✅

**아카이브 (보존):**
- `docs/archive/vsomeip-tests/` (8개 문서, 161.4KB)

---

## 🚀 다음 단계

1. **vsomeip 통합 문서 생성** ⏭️
   - 위 구조로 `docs/VSOMEIP_RASPIOS_IMPLEMENTATION_GUIDE.md` 작성
   - 기존 문서들의 핵심 내용 통합
   
2. **기존 문서 아카이브**
   ```bash
   mkdir -p docs/archive/vsomeip-tests
   mv docs/전체통신테스트.md docs/archive/vsomeip-tests/
   mv docs/기어-Vehicle앱통신.md docs/archive/vsomeip-tests/
   mv docs/통신테스트_라우팅_SD.md docs/archive/vsomeip-tests/
   mv docs/ECU2_DEPLOYMENT_ROUTING_MANAGER.md docs/archive/vsomeip-tests/
   mv docs/ROUTING_MANAGER_MIGRATION_COMPLETE.md docs/archive/vsomeip-tests/
   mv docs/ECU_BOOT_TO_COMMUNICATION_GUIDE.md docs/archive/vsomeip-tests/
   mv docs/ECU_COMMUNICATION_TROUBLESHOOTING_GUIDE.md docs/archive/vsomeip-tests/
   mv docs/DEPLOYMENT_GUIDE.md docs/archive/vsomeip-tests/
   ```

3. **README 업데이트**
   - 프로젝트 루트 README에 새 문서 링크 추가

---

## 📊 정리 효과

### 삭제된 용량
- Phase 1: ~1.2MB
- Phase 2: ~100KB
- **총:** ~1.3MB

### 문서 정리
- **통합 전:** 15개 문서 (vsomeip 관련)
- **통합 후:** 1개 핵심 문서 + 아카이브
- **효과:** 검색성 향상, 중복 제거

### 구조 개선
- ✅ 중복 제거
- ✅ 명확한 디렉토리 구조
- ✅ 최신 정보 중심 정리
