# 꽃갈피 협업 · 서명 · 배포

배포 계정은 **동영(김동영)** Apple Developer 팀입니다. 앱은 친구가 만들고, 실기기 테스트와 TestFlight 업로드는 같은 팀으로 합니다.

## 역할

| 사람 | Apple | GitHub | 하는 일 |
| --- | --- | --- | --- |
| 동영 | Account Holder `hellrot99@nate.com` / Team `7H8779959T` | `dahli4` | 계정·인증서·스토어 소유, 심사 제출 |
| 성현 | App Manager `writer161@live.co.kr` | `nbyvsmn4cr-source` | 코드, 실기기 실행, TestFlight 업로드 |

작업 저장소는 배포 계정 포크입니다.

- 작업/배포: https://github.com/dahli4/ggotgalpi-demo
- 원본 데모: https://github.com/nbyvsmn4cr-source/ggotgalpi-demo

```bash
git clone https://github.com/dahli4/ggotgalpi-demo.git
cd ggotgalpi-demo
open GgotgalpiDemo.xcodeproj
```

이미 원본을 클론했다면:

```bash
git remote add dahli4 https://github.com/dahli4/ggotgalpi-demo.git
git fetch dahli4
git checkout main
git merge dahli4/main
```

## 고정값 — 바꾸지 말 것

Xcode Target → Signing & Capabilities:

- **Team:** DongYoung Kim (`7H8779959T`)
- **Bundle Identifier:** `com.dahli4.ggotgalpi`
- **Signing:** Automatically manage signing

팀이나 Bundle ID를 개인 팀으로 바꾸면 실기기·TestFlight가 깨집니다.

## 친구가 실기기에 실행

1. Xcode → Settings → Accounts에 `writer161@live.co.kr`을 추가합니다.
2. 프로젝트를 열고 Signing의 Team이 **DongYoung Kim**인지 확인합니다.
3. iPhone을 맥에 연결하고 Trust 한 뒤, 기기 대상과 `GgotgalpiDemo` 스킴으로 Run 합니다.
4. 처음이면 Xcode가 Development 인증서와 프로비저닝 프로필을 자동 발급하고, 기기를 팀에 등록합니다.
5. iPhone 설정 → 일반 → VPN 및 기기 관리에서 개발자 앱을 신뢰해야 할 수 있습니다.

시뮬레이터만 돌릴 때는 서명이 필요 없습니다.

## 친구가 TestFlight에 올리는 방법

로컬에서 Distribution 인증서 개인키가 없는 맥이 많습니다. **GitHub Actions를 기본 배포 경로로 씁니다.**

1. 변경을 `dahli4/ggotgalpi-demo`의 `main`에 푸시합니다.
2. GitHub → Actions → **TestFlight** → Run workflow.
3. 처리가 끝나면 App Store Connect → TestFlight에서 빌드를 확인합니다.

로컬에서 올리는 경우(동영 맥, API 키가 있는 환경):

```bash
bundle install
bundle exec fastlane ios beta
```

또는:

```bash
./scripts/upload-testflight.sh
```

Xcode Organizer로 Archive → Distribute 해도 됩니다. 이때도 Team은 DongYoung Kim이어야 합니다.

## 동영이 한 번만 해 두면 되는 것

Apple 팀 초대는 이미 되어 있습니다(성현 = App Manager).

이미 되어 있는 것:

- Apple 팀: 성현(`writer161@live.co.kr`) App Manager
- Developer Portal Bundle ID: `com.dahli4.ggotgalpi`
- GitHub Write 초대: `nbyvsmn4cr-source` → `dahli4/ggotgalpi-demo` (수락 필요)
- GitHub Actions Secrets: `APP_STORE_CONNECT_API_KEY_ID` / `ISSUER_ID` / `API_KEY`

동영이 콘솔에서 한 번만 만들면 되는 것:

1. [App Store Connect](https://appstoreconnect.apple.com) → My Apps → +
   - Platforms: iOS
   - Name: 꽃갈피
   - Primary Language: Korean
   - Bundle ID: `com.dahli4.ggotgalpi`
   - SKU: `ggotgalpi`
   - 사용자 액세스: 전체(성현 포함)

`.p8` / `.p12` / 프로비저닝 프로필은 git에 넣지 않습니다.

## 문제 해결

| 증상 | 보통 원인 |
| --- | --- |
| Failed to register bundle identifier | Bundle ID를 개인 팀으로 바꿈 |
| No signing certificate / team not found | Xcode에 팀 멤버 Apple ID가 없음 |
| Communication with Apple failed | 네트워크, 2FA, 세션 만료. Xcode Accounts에서 재로그인 |
| Archive는 되는데 Upload 실패 | Distribution 개인키가 이 맥에 없음 → Actions로 업로드 |
| CI가 secret missing | `dahli4/ggotgalpi-demo` Settings → Secrets에 API 키 3개 없음 |
