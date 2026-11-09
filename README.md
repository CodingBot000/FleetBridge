# FleetBridge

UIKit 차량 목록에서 Flutter 차량 상세로 이동하는 Add-to-App PoC입니다. 실제 차량 데이터나 제어 기능은 포함하지 않습니다.

## 개발 환경 준비

macOS, Xcode와 iOS Simulator, Flutter 3.47.9 Stable이 필요합니다. Flutter를 PATH에 추가한 뒤 저장소 루트에서 실행합니다.

```sh
./scripts/bootstrap-ios.sh
open FleetBridgeHost/FleetBridgeHost.xcodeproj
```

스크립트는 잠금 파일을 검증하고 Flutter Swift 패키지를 생성합니다. 생성물은 Git에 포함되지 않으므로 클론 후 다시 실행해야 합니다. 스크립트의 서명 없는 패키지는 시뮬레이터 개발용입니다. 실기기 및 배포 서명은 별도 설정이 필요합니다.

Xcode에서 `FleetBridgeHost` Scheme과 iOS Simulator를 선택해 빌드·테스트합니다. Flutter 검증은 `cd fleetbridge_detail && flutter test && flutter analyze`로 실행합니다. Flutter 의존성을 변경한 뒤에는 초기화 스크립트를 다시 실행합니다.
