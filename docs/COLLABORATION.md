# 꽃갈피 — 누가 무엇을

앱 코드는 친구가 만들고 GitHub도 친구 저장소가 원본입니다.  
동영은 그 저장소를 클론해서, **자기 Apple Developer 계정으로만** 실기기 서명과 스토어 배포를 합니다.

| | 동영 | 친구 |
| --- | --- | --- |
| GitHub | 클론해서 받아옴 | 원본 저장소 주인 |
| Apple | 계정 주인 (Team `7H8779959T`) | 그 팀에 App Manager로 들어가 있음 |
| 하는 일 | TestFlight / 앱스토어 업로드 | 코드, 시뮬레이터, 실기기 실행 |

원본: https://github.com/nbyvsmn4cr-source/ggotgalpi-demo

Xcode에서 **바꾸지 말 값**

- Team: **DongYoung Kim** (`7H8779959T`)
- Bundle ID: `com.dahli4.ggotgalpi`
- Signing: Automatically manage signing

---

## 동영 (이미 된 것 / 남은 것)

된 것

- Apple 팀에 친구(`writer161@live.co.kr`) App Manager로 들어가 있음
- Bundle ID `com.dahli4.ggotgalpi` 등록됨
- 이 클론에 Automatic Signing, 팀, Bundle ID가 박혀 있음
- 로컬 업로드 스크립트: `./scripts/upload-testflight.sh` / `bundle exec fastlane ios beta`

동영이 콘솔에서 한 번만

1. Xcode → Settings → Accounts에 `hellrot99@nate.com` 로그인 (이 맥에 인증서가 내려옴)
2. [App Store Connect](https://appstoreconnect.apple.com) → My Apps → **+**
   - iOS
   - 이름: 꽃갈피
   - 언어: Korean
   - Bundle ID: `com.dahli4.ggotgalpi`
   - SKU: `ggotgalpi`
3. 이후 배포는 이 맥에서:

```bash
cd ~/Documents/ggotgalpi-demo
./scripts/upload-testflight.sh
```

Git은 친구 원본을 `origin`으로 두고 풀 받으면 됩니다. Apple 키(`.p8`)는 git에 넣지 않습니다.

---

## 친구에게 시키면 되는 것

카톡/슬랙에 그대로 보내도 됩니다.

1. 저장소는 지금처럼 **자기 GitHub** 쓰면 됨. 동영 포크로 옮기지 말 것.
2. 동영이 올린 PR(서명 설정)을 머지하면 Team/Bundle ID가 프로젝트에 들어감.
3. Xcode → Settings → Accounts에 **Apple 팀 초대받은 메일** (`writer161@live.co.kr`) 로그인.
4. `GgotgalpiDemo.xcodeproj` 열고 Signing & Capabilities에서
   - Team = **DongYoung Kim**
   - Bundle Identifier = `com.dahli4.ggotgalpi`
   - Automatically manage signing 켜짐
   - 개인 팀이나 다른 Bundle ID로 바꾸지 말 것.
5. iPhone 연결 → Trust → 스킴 `GgotgalpiDemo`로 Run.
6. 처음이면 아이폰 설정 → 일반 → VPN 및 기기 관리에서 개발자 앱 신뢰.
7. 시뮬레이터만 쓸 때는 서명 신경 안 써도 됨.
8. 앱스토어/TestFlight 업로드는 동영이 함. 친구가 Archive로 올리지 않아도 됨.

안 되면 거의 항상 Team을 개인 계정으로 바꿔서입니다. DongYoung Kim으로 되돌리면 됩니다.
