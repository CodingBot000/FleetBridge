# 검증 결과와 근거

이 문서는 `v1.0-add-to-app`에 이르기까지 기록된 검증을 정리합니다. 문서를 갱신했다고 과거의 로컬 테스트가 다시 실행된 것은 아닙니다. 이번 문서 PR의 CI 상태는 해당 PR의 Checks를 확인하세요.

## 기록된 실행과 범위

| 단계 / 기준 | 환경 | 기록된 결과 | 근거 |
|---|---|---|---|
| Phase 1 최종 `4d23ed9` | Xcode 26.6, iPhone 16 iOS 18.6 Simulator | XCTest 8개(launch 테스트의 환경별 반복 포함 실행 수는 별도), Flutter 테스트 4개 통과 | [Phase 1 PR](https://github.com/CodingBot000/FleetBridge/pull/1), [당시 계약](specs/phase1.md) |
| Phase 2 기능 `11b69c8` | Xcode 26.6 Simulator / 로컬 Flutter | XCTest 11개, Flutter 테스트 8개 및 분석 통과 | [Phase 2 PR](https://github.com/CodingBot000/FleetBridge/pull/3), [CI](https://github.com/CodingBot000/FleetBridge/actions/runs/42580264667) |
| Phase 2 지도 보완 `b9ec56e` | Xcode Simulator / Ubuntu CI | XCTest 회귀 11개, Flutter 테스트 9개 및 분석 통과 | [지도 보완 커밋](https://github.com/CodingBot000/FleetBridge/commit/b9ec56e), [CI](https://github.com/CodingBot000/FleetBridge/actions/runs/42582768576) |
| Phase 3 검증 후 최종 보강 `1659053` | Xcode 26.6, iOS 26.5 Simulator / Ubuntu CI | 전체 XCTest 15개 통과 후 생명주기 변경 관련 UI 테스트 2개 재실행, 지연 응답 대기를 보강한 테스트 1개 재실행. Flutter 테스트 12개 및 분석 통과 | [Phase 3 PR의 검증 기록](https://github.com/CodingBot000/FleetBridge/pull/4), [CI](https://github.com/CodingBot000/FleetBridge/actions/runs/42585337801) |

XCTest 개수에는 기본 템플릿의 `testExample`과 빈 측정 블록도 포함됩니다. 총 개수를 기능 커버리지로 해석하지 않고 아래 시나리오를 확인해야 합니다. XCTest 결과 번들과 콘솔은 당시 로컬 실행 산출물이며 공개 저장소에 전부 보존되어 있지는 않습니다. 공개 PR의 기록과 테스트 소스를 근거로 연결하며, CI 링크는 Flutter 검증만 증명합니다.

## 시나리오와 테스트 연결

| 시나리오 | 테스트 위치와 이름 | 확인 범위 |
|---|---|---|
| 차량 10대의 고유 ID·조회·누락 ID | [Native 테스트](../FleetBridgeHost/FleetBridgeHostTests/FleetBridgeHostTests.swift) `testMockVehiclesHaveUniqueIDsAndCanBeLookedUp` | 저장소 단위 검증 |
| 위치·운행 상태 갱신과 offline 유지 | 같은 파일 `testAdvanceMovesDrivingAndLeavesOfflineUnchanged` | 모의 시뮬레이터 동작 |
| 중복 명령·성공·실패·시간 초과 | 같은 파일 `testCommandSuccessAndDuplicateAreHandled`, `testCommandFailureAndTimeout` | Native 모의 명령 처리 |
| 차량 1·2를 번갈아 20회 진입·복귀 | [UI 테스트](../FleetBridgeHost/FleetBridgeHostUITests/FleetBridgeHostUITests.swift) `testVehicleDetailSwitchesBetweenSelections` | 실제 Native ↔ Flutter 화면 경로 |
| 잘못된 ID의 오류 화면과 복귀 | 같은 파일 `testInvalidVehicleShowsErrorAndReturnsToList` | Debug 입력으로 실제 MethodChannel 경로 검증 |
| 앱 백그라운드·복귀 | 같은 파일 `testBackgroundAndReturnToDetail`; Native `testSimulatorStartStopIsIdempotent` | 화면 유지·복귀, 타이머 시작·종료의 멱등성 |
| 종료된 화면의 늦은 명령 응답 | 같은 파일 `testLateCommandAfterCloseDoesNotAffectNextDetail` | 모의 시간 초과보다 오래 기다린 후 다음 차량 화면에 결과가 섞이지 않는지 확인 |
| 초기 핸들러 미등록·오류·중복/역순 이벤트 | [Flutter 테스트](../fleetbridge_detail/test/widget_test.dart) | 응답 대체와 `VehicleRevisionGate`의 단위·위젯 검증 |
| 지도 요청 차단·지도 실패·갱신 지연·복귀 재조회 | 같은 파일 | 공용 지도 서버 없이 가짜 타일과 채널로 검증 |
| 첫 렌더 지연 | UI `testThirtyFirstFrames` | [별도 측정 조건과 CSV](performance/first-frame.md); 사용자 체감 전체 로딩 시간 아님 |

## CI 성공과 실패 차단

[워크플로](../.github/workflows/flutter-ci.yml)는 `main` 대상 PR에서 Flutter 3.47.9, 잠금 파일 검증, 분석과 테스트를 Ubuntu에서 실행합니다. macOS Runner나 Xcode 테스트는 이 워크플로에 없습니다.

[성공 실행](https://github.com/CodingBot000/FleetBridge/actions/runs/42577934165)과 [의도적인 실패 실행](https://github.com/CodingBot000/FleetBridge/actions/runs/42578131463)을 구분합니다. 별도 실패 테스트가 exit code 1을 반환한 뒤 PR #2의 병합 상태가 `BLOCKED`임을 확인했고, 검증용 PR을 닫고 브랜치를 삭제했습니다. [PR #1의 기록](https://github.com/CodingBot000/FleetBridge/pull/1)에 보호 정책과 실험 결과를 남겼습니다. 이 결과는 당시 정책 검증이며 향후 설정 변경까지 보장하지는 않습니다.

## 재실행과 미검증 항목

[README의 명령](../README.md#검증)으로 Flutter와 Xcode 검증을 각각 실행합니다. 기록된 로컬 재현성 검증에는 별도 클론에서의 패키지 생성과 Simulator 빌드가 포함됩니다. 매 문서 변경마다 새 클론과 iOS 전체 테스트를 다시 실행한 것은 아닙니다.

실기기, 실제 iOS 18.0, Release/Profile 성능, 엔진 재사용 비교 및 유효한 Instruments 메모리 결과는 미검증입니다. 메모리 프로파일링은 시도했지만 유효한 수치를 확보하지 못했습니다. 화면 반복 진입 테스트 통과를 누수 없음의 증거로 해석하지 않습니다. 실제 차량·서버·단말 네트워크 감지는 구현 범위 밖입니다.
