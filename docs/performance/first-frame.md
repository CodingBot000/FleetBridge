# Flutter 첫 렌더 측정

2026-11-09, Apple M4 Max / macOS 26.5.1 / Xcode 26.6 / Flutter 3.47.9, iPhone 17 Pro iOS 26.5 Simulator, Debug 빌드. PR #3의 `b9ec56e`에 측정 코드만 임시로 추가하여 실행했다. 차량 1과 2를 번갈아 열고 닫았다. 공용 지도 타일과 지도의 네트워크 지연은 자동 테스트 모드에서 제외했다. 같은 머신에서 다른 개발 작업이 일부 실행되어 격리된 벤치마크는 아니다.

`VehicleDetailCoordinator.present` 내부에서 중복 진입 검사 후 엔진 생성 전에 읽은 단조 시계와 `FlutterViewController.setFlutterViewDidRenderCallback` 첫 호출 사이를 측정했다. 이는 실제 화면의 광자 표시 시간이나 전체 차량 데이터 로딩 시간이 아니라 Flutter의 첫 렌더 콜백까지의 시간이다. 첫 샘플을 포함한 30회 중앙값은 **550.731ms**, nearest-rank p95는 **650.091ms**다. [원시 수치](first-frame-simulator.csv)를 함께 기록한다.

측정 테스트는 Xcode `FleetBridgeHostUITests/testThirtyFirstFrames`이며, Debug에서만 계측 UI가 활성화된다. 실기기, Release/Profile, 메모리 증가 및 엔진 재사용 방식은 측정하지 않았다. 따라서 이 수치만으로 엔진 재사용이 느리거나 빠르다고 결론낼 수 없다. 현재 구현은 검증된 차량별 상태 격리와 단순한 해제 책임 때문에 유지하며, 재사용 여부는 실기기에서 동등 조건의 별도 비교 후 결정한다.

재실행 예시(프로젝트 루트, 먼저 초기화 스크립트 실행):

```sh
xcodebuild test -project FleetBridgeHost/FleetBridgeHost.xcodeproj \
  -scheme FleetBridgeHost \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO \
  -only-testing:FleetBridgeHostUITests/FleetBridgeHostUITests/testThirtyFirstFrames
```

테스트 출력의 `FLEET_MEASUREMENT` 값은 각 Flutter 첫 렌더 콜백 시간이다. Simulator 상태와 다른 작업에 따라 결과가 달라진다. Instruments Allocations 연결을 시도했으나 테스트 프로세스 종료와 기록 종료 지연으로 유효한 메모리 수치를 확보하지 못했다.

## 측정 코드의 추적성과 재현 한계

CSV는 위 임시 계측 실행에서 얻은 원시 기록이며 이번 문서 정리에서 변경하거나 재측정하지 않았습니다. 당시 임시 패치를 별도 커밋으로 보존한 것은 아니므로 `b9ec56e`만으로 원래 작업 트리를 그대로 복원할 수는 없습니다.

계측 경로는 이후 [3b2d0ba](https://github.com/CodingBot000/FleetBridge/commit/3b2d0ba)에 정식 코드로 추가됐습니다. 고정된 [v1.0 소스](https://github.com/CodingBot000/FleetBridge/tree/v1.0-add-to-app)에서 [Native 콜백](../../FleetBridgeHost/FleetBridgeHost/VehicleDetailCoordinator.swift)과 [30회 UI 테스트](../../FleetBridgeHost/FleetBridgeHostUITests/FleetBridgeHostUITests.swift)를 확인하고 같은 방식의 새 실험을 할 수 있습니다. 이것은 원래 임시 패치의 동일성이나 수치 재현을 보장하는 설명이 아닙니다.

## 저장된 CSV의 통계 재계산

저장소 루트에서 아래 명령을 실행합니다. 새 측정 없이 기존 CSV만 읽으며 첫 샘플을 포함합니다. p95는 정렬 후 `ceil(0.95 × n)`번째 값입니다.

```sh
python3 - <<'PYTHON'
import csv
import math
import statistics
from pathlib import Path

path = Path("docs/performance/first-frame-simulator.csv")
with path.open() as source:
    values = [float(row["first_frame_ms"]) for row in csv.DictReader(source)]
assert len(values) == 30
print(f"n={len(values)}")
print(f"median={statistics.median(values):.3f} ms")
print(f"p95={sorted(values)[math.ceil(0.95 * len(values)) - 1]:.3f} ms")
PYTHON
```

CSV의 정밀도를 보존한 수치 표기이며 0.001ms 수준의 실험 정확도를 의미하지 않습니다. 현재 결과는 cold/warm 조건을 분리한 대조 실험이 아니고, 첫 프레임 이후의 차량 조회·지도 로딩·애니메이션 완료도 측정 대상이 아닙니다.
