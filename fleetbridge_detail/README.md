# FleetBridge Flutter 상세 화면

UIKit Host에서 차량을 선택하면 표시되는 Add-to-App 화면입니다. 차량 저장소와 명령 시뮬레이션은 Native가 소유하고, Flutter는 Riverpod으로 조회 결과와 화면 상태를 관리합니다. [전체 실행 방법](../README.md)을 먼저 확인하세요.

## 역할과 의존성

- 초기 라우트의 `id`로 차량을 조회하고 `vehicleUpdated` 알림의 revision을 검사합니다.
- 지도, 모의 연결 상태·갱신 지연, 냉동기 명령 결과를 표시합니다.
- `fleetbridge/vehicle` MethodChannel로 Native의 조회·명령·닫기 기능을 호출합니다.
- `ios/Runner`는 Flutter 도구가 생성한 보조 앱이며 포트폴리오의 Native Host는 `../FleetBridgeHost`입니다. 이 폴더에서 `flutter run`만 실행하면 Host의 채널 구현이 없어 정상 차량 데이터가 표시되지 않습니다.

[채널 계약과 설계 결정](../docs/architecture.md) · [검증 근거](../docs/verification.md)

## 모듈 검증

이 폴더에서 실행합니다. 테스트는 Native 응답과 지도 타일을 대체하므로 Simulator나 공용 지도 서버를 필요로 하지 않습니다.

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
```

Native ↔ Flutter 실제 왕복은 별도의 Xcode UI 테스트로 확인합니다. 의존성 변경 후에는 저장소 루트의 `scripts/bootstrap-ios.sh`를 다시 실행해야 합니다.
