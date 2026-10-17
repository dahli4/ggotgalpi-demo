# 꽃갈피

읽은 책과 그날의 감상을 달력으로 돌아보는 SwiftUI 앱입니다. 책과 감상은 SwiftData에 보관하며, Apple 측 설정을 마치면 같은 iCloud 계정의 기기 사이에서 동기화합니다.

## 주요 화면

- **감상 달력**: iOS 기본 그래픽 캘린더에서 날짜를 고르고 그날의 감상을 확인합니다.
- **책장**: 분야별 책을 살펴보고 새 책을 추가합니다.
- **나의 감상**: 최근 감상과 간단한 독서 통계를 확인합니다.
- **책 상세**: 회독, 페이지 범위, 감상 기록을 관리합니다.

## 개발 환경

- Xcode 16 이상
- iOS 17 이상
- Swift 5, SwiftUI

외부 패키지나 별도 API 키는 필요하지 않습니다.

## 시작하기

```bash
git clone https://github.com/nbyvsmn4cr-source/ggotgalpi-demo.git
cd ggotgalpi-demo
open GgotgalpiDemo.xcodeproj
```

Xcode에서 `GgotgalpiDemo` 스킴과 iPhone 시뮬레이터를 선택한 뒤 실행합니다.

실기기에서 실행하거나 배포하려면 기존 앱의 개발 팀과 Bundle Identifier를 먼저 확인하세요. 식별자를 바꾸면 별도 앱과 저장 공간이 되어 기존 기록을 자동으로 이어받을 수 없습니다.

서명 없이 명령줄 빌드를 확인하려면 다음 명령을 사용할 수 있습니다.

```bash
xcodebuild \
  -project GgotgalpiDemo.xcodeproj \
  -scheme GgotgalpiDemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 프로젝트 구조

```text
GgotgalpiDemo/
├── App/                    # 앱 진입점과 기본 탭
│   ├── GgotgalpiDemoApp.swift
│   └── ContentView.swift
├── Core/                   # 모델, 저장소, 디자인 토큰
│   ├── Models.swift
│   └── Theme.swift
└── Features/               # 기능별 화면
    ├── Calendar/
    ├── Library/
    └── Journal/
```

화면을 바꾸기 전에 [DESIGN.md](DESIGN.md)의 토큰과 컴포넌트 규칙을 확인해 주세요.

## 기여하기

작은 버그 수정부터 환영합니다. 작업 전 이슈를 확인하고, 변경 목적이 하나인 브랜치와 Pull Request를 만들어 주세요. 상세 절차와 품질 기준은 [CONTRIBUTING.md](CONTRIBUTING.md)에 있습니다.

저장소 테스트 실행 방법은 [Tests/README.md](Tests/README.md)에 있습니다.

## iCloud 동기화

책의 정보·독서 상태와 감상·문장·별점·회독·휴지통 상태는 SwiftData와 CloudKit으로 동기화합니다. 즐겨찾는 작가, 날짜별 책 순서, 휴지통 보관 기간은 iCloud 키-값 저장소를 사용합니다. 책장 정렬과 표시 옵션은 기기별 설정입니다.

기존 설정은 기기에 보존합니다. 원격 설정이 아직 없으면 기존 값을 보여 주며, 다른 기기의 늦은 초기 내려받기를 덮어쓰지 않도록 사용자가 다시 변경할 때 업로드합니다. 설정 충돌은 키별 마지막 쓰기가 우선하므로 동시에 바꾼 작가 목록이나 달력 순서는 한쪽 값으로 교체될 수 있습니다. iCloud 로그인이나 네트워크가 없더라도 로컬 기록은 유지합니다.

오너가 Apple 측에서 해야 할 일:

1. 오너가 정한 현재 App ID `com.dahli4.ggotgalpi`를 유지합니다. 예전 개발 빌드 `com.ggotgalpi.demo`를 설치한 기기의 기록은 별도 저장 공간에 있으므로 필요한 기록을 보존한 뒤 개발 앱을 정리합니다. 이는 새 식별자의 첫 출시 자체를 막는 문제는 아닙니다. 서명 브랜치를 합칠 때 옛 식별자로 되돌아가지 않는지 확인합니다.
2. Apple Developer의 사용할 App ID에서 iCloud/CloudKit과 키-값 저장을 활성화하고 `iCloud.com.dahli4.ggotgalpi` 컨테이너를 만들거나 연결합니다. 프로젝트의 실제 서명 팀과 일치하는 권한·프로파일을 사용합니다.
3. 개발용 빌드로 스키마를 만든 뒤 CloudKit Dashboard에서 확인합니다. 스토어 배포 전에는 스키마를 **Production으로 배포**합니다. 배포한 스키마는 기본적으로 추가만 가능하므로 필드 변경을 먼저 검토합니다.
4. 같은 iCloud 계정으로 로그인한 실기기 두 대에 같은 앱을 설치합니다. 첫 기기에서 고유한 책·감상·별점·문장을 만들고 두 번째 기기에서 확인합니다. 이어서 작가 즐겨찾기·달력 순서·보관 기간을 바꾸고 반대 기기와 재실행 후에도 같은지 확인합니다. 휴지통 이동·복구와 오프라인 작성 후 재연결도 확인합니다.

시뮬레이터에서 로컬 컨테이너 생성과 기존 저장소 이전은 확인할 수 있지만, Apple 측 준비와 실기기 두 대 없이 실제 기기 간 동기화 성공을 주장할 수는 없습니다. 서명 없는 빌드 명령은 컴파일 확인용입니다. CloudKit 실행 검증에는 Xcode가 시뮬레이터 권한을 포함해 만든 실행용 빌드가 필요합니다.

새 저장소에는 예제 기록을 자동으로 넣지 않습니다. QA에서만 실행 인자 `-seed-sample-data`로 기존 예제를 넣을 수 있습니다. 현재 앱은 밝은 테마를 일관되게 사용하며, 완전한 다크 테마는 별도 작업입니다.

## 라이선스

[MIT License](LICENSE)로 배포됩니다.
