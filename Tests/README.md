# 저장소 테스트

macOS와 Xcode 명령줄 도구에서 실행합니다. 앱 테스트 타깃이나 외부 패키지는 필요하지 않습니다.

```sh
build_dir="$(mktemp -d /tmp/ggotgalpi-tests.XXXXXX)"
xcrun swiftc -swift-version 6 -warnings-as-errors -parse-as-library \
  GgotgalpiDemo/Core/SyncedSettings.swift Tests/SyncedSettingsTests.swift \
  -o "$build_dir/settings-tests"
"$build_dir/settings-tests"
xcrun swiftc -swift-version 5 -warnings-as-errors -parse-as-library \
  GgotgalpiDemo/Core/SyncedSettings.swift GgotgalpiDemo/Core/Models.swift \
  Tests/DemoStoreTests.swift -o "$build_dir/store-tests"
"$build_dir/store-tests"
rm -rf "$build_dir"
```

공유 작업 환경에서는 컴파일과 실행 명령 앞에 `dori heavy <label> --`를 붙입니다.

- 설정 테스트는 주입한 가짜 iCloud 저장소, 격리된 UserDefaults, 별도 알림 센터를 사용합니다. 실제 계정에 접근하지 않습니다.
- 기존 값 대체, 늦게 도착한 원격 값, 빈 값, 잘못된 값, 계정 변경, 로컬 쓰기와 외부 알림을 검사합니다. 고정 대기나 시간에 의존하는 검사는 없습니다.
- 통합 테스트는 실제 메모리 SwiftData 컨테이너와 `DemoStore`를 사용합니다. 관계와 연결 삭제, 세 설정의 쓰기와 외부 변경 반영, 보관 기간에 따른 삭제, 다른 컨텍스트에서 저장한 책의 새로 고침을 검사합니다.
- 각 테스트는 실패하면 0이 아닌 코드로 종료하며 격리된 UserDefaults를 정리합니다.

설정 충돌은 키별 마지막 쓰기가 우선합니다. 유효한 원격 값이 있으면 사용하고, 없으면 기존 기기 설정을 대체값으로 보존합니다. 초기 내려받기를 기다리는 동안 다른 기기의 값을 덮어쓰지 않도록 기존 값은 사용자가 다시 변경할 때 업로드합니다. 원격 빈 목록은 목록 비우기이며 키 없음과 다릅니다. 원격 값은 다른 계정의 로컬 대체값으로 복사하지 않습니다.

이 검사는 Apple 서버 전달이나 두 기기의 실제 동기화를 증명하지 않습니다. 해당 검사는 Apple 측 설정과 실기기 두 대로 별도 진행해야 합니다.
