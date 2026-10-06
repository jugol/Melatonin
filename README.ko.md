<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Melatonin 아이콘">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>뚜껑은 닫고, 에이전트는 계속.</b><br>
  맥북 뚜껑을 닫아도 잠들지 않게 해주는 작은 메뉴바 앱이에요.<br>
  배터리만으로도, 외장 모니터 없이도 Claude Code·Codex 작업이 끝까지 돌아가요.
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>다운로드</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">웹사이트</a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.ar.md">العربية</a> ·
  <a href="README.hi.md">हिन्दी</a> ·
  <a href="README.id.md">Bahasa Indonesia</a>
</p>

<p align="center">
  <img src="docs/images/notch-expanded-on.png" width="640" alt="노치에서 펼쳐진 Melatonin">
</p>

## 왜 만들었나

Claude Code에 긴 작업을 맡기고 뚜껑을 닫고 자리를 비우면, 맥이 잠들면서 작업이 끊겨요.

`caffeinate`, KeepingYouAwake 같은 앱들은 "잠들지 마" 요청(power assertion)을 쓰는데, macOS는 뚜껑이 닫히는 순간 이 요청을 무시해요. 뚜껑을 닫아도 잠들지 않게 하는 확실한 방법은 `pmset disablesleep`뿐이고, 이건 관리자 권한이 필요해요. Melatonin은 이걸 작고 안전한 헬퍼로 감싸고, 스위치를 한눈에 보이는 노치에 올려놨어요.

## 기능

- **노치에 살아요.** 켜져 있으면 카메라 옆에 따뜻한 램프가 빛나고 남은 시간이 보여요. 마우스를 올리면 전체 조작 패널로 펼쳐져요. 노치가 없는 모니터에서는 메뉴바 가운데에 알약 모양으로 붙어요.
- **메뉴바 스위치.** 초승달 테두리만 보이면 잠드는 상태, 초승달이 주황 램프를 품고 있으면 깨어 있는 상태예요.
- **타이머.** 1·2·4·8시간, 또는 직접 끌 때까지.
- **달 · 자동 · 해.** 램프 아래 스위치 하나로 정해요. **끔**은 맥이 잠들게 두고, **자동**은 에이전트가 일하는 동안만 깨워두고, **켬**은 타이머가 끝날 때까지 깨워둔 뒤 원래 모드로 돌아가요.
- **AI 에이전트 자동 감지.** Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI, Cursor Agent, Amp, Goose, Crush가 실제로 일하는 동안에만 깨어 있어요. 에이전트와 그 하위 프로세스의 CPU 사용량을 보기 때문에 프롬프트 앞에서 대기 중인 에이전트는 치지 않아요. Claude Code와 Codex는 대화 기록도 읽어서, 모델이 오래 생각하거나 조용히 도는 명령, 백그라운드 서브에이전트도 일하는 중으로 쳐요. T3 Code가 띄운 에이전트는 T3 Code로 표시돼요.
- **연결 유지.** 맥이 깨어 있는 동안 인터넷이 끊기면(예: 뚜껑을 닫고 사무실 Wi-Fi 범위를 벗어났을 때), 저장된 네트워크 중에서 고른 우선순위 목록을 위에서부터 보고 범위 안에 있는 첫 번째 네트워크(휴대폰 핫스팟 등)에 연결해요. 이름으로 네트워크를 고르려면 위치 권한이 필요해요. macOS가 위치 권한이 있는 앱에만 Wi-Fi 이름을 보여주기 때문이고, 위치 자체는 쓰지 않아요. 모두 실패하면 Wi-Fi를 껐다 켜서 macOS가 저장된 네트워크에 알아서 붙게 해요.
- **자리 비운 사이.** 맥으로 돌아오면 노치가 그동안 있었던 일을 알려줘요. 얼마나 깨워뒀는지, 어떤 에이전트가 얼마나 일했는지, Wi-Fi 끊김을 몇 번 복구했는지, 배터리를 얼마나 썼는지요.
- **안전장치.**
  - 배터리로 쓸 때 정한 잔량(기본 20%) 아래로 떨어지면 꺼져요.
  - 맥이 뜨거워지면 꺼져요. 켜진 노트북을 닫힌 가방에 넣으면 배터리가 익어요.
  - 앱이 종료되거나, 크래시 나거나, 강제 종료돼도 헬퍼가 즉시 원래대로 잠자기를 되돌려요. 재부팅한 뒤에도 정리해요.
- **가볍고 네이티브.** SwiftUI + AppKit, Electron 없음, 대기 중 CPU 약 0%. Apple 실리콘·Intel 유니버설 빌드.
- **12개 언어.** English, 한국어, 简体中文, 日本語, Español, Français, Deutsch, Português (Brasil), Русский, العربية, हिन्दी, Bahasa Indonesia. 기본은 macOS 언어를 따르고, **⋯ › 언어**에서 바꿀 수 있어요.

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="메뉴 - 깨어 있음">
  <img src="docs/images/menu-off-dark.png" width="300" alt="메뉴 - 잠들 수 있음">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="남은 시간이 보이는 노치 알약">
</p>

<p align="center">
  <img src="docs/images/notch-recap.png" width="640" alt="노치에 뜬 자리 비운 사이 요약">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="연결 유지 설정">
</p>

## 설치

macOS 14 Sonoma 이상이 필요해요.

**다운로드:** [최신 릴리스](https://github.com/jugol/Melatonin/releases/latest)에서 [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg)를 받아 응용 프로그램 폴더로 드래그하세요.

**Homebrew:**

```bash
brew install --cask jugol/tap/melatonin
```

릴리스는 Developer ID로 서명하고 Apple 공증을 받아서 다른 앱처럼 바로 열려요.

Melatonin은 스스로 업데이트해요. 새 버전이 나오면 메뉴 위쪽에 작은 배지가 뜨고, **⋯ › 업데이트 확인…**에서 직접 확인할 수도 있어요.

처음 켤 때 헬퍼 설치를 위해 비밀번호를 한 번 물어봐요.

**소스로 빌드:** Xcode Command Line Tools(`xcode-select --install`)가 필요해요.

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## 동작 방식

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, 타이머,              pmset -a disablesleep 1 / 0
  안전 검사,                …앱 연결이 끊기면 다시 0으로
  연결 감시                 networksetup -setairportpower (Wi-Fi 끄고 켜기)
```

- **헬퍼가 하는 일은 아주 적어요.** 인터페이스는 `setSleepDisabled(Bool)`과 Wi-Fi 호출 두 개(Wi-Fi 재시작, 맥에 저장된 네트워크 연결)뿐이에요. 셸 접근도, 임의 명령 실행도 없어요. [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift)
- **Melatonin 앱하고만 대화해요.** XPC 연결은 앱 번들 ID에 대한 코드 서명 조건을 통과해야 해요.
- **안전하게 실패해요.** 연결된 앱이 요청하는 동안에만 잠자기가 꺼져 있어요. 연결이 끊기면 원래대로 돌아와요. 헬퍼 재시작이나 재부팅은 마커 파일로 처리해요.
- **설치·제거는 읽을 수 있는 셸 스크립트예요.** [`Support/install-helper.sh`](Support/install-helper.sh), [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh)

## 제거

메뉴에서 **⋯ › 헬퍼 제거…**를 누른 뒤 앱을 지우세요. 직접 지우려면:

```bash
sudo bash Support/uninstall-helper.sh
```

## 개발

```bash
make app        # build build/Melatonin.app (signed with the best identity on this Mac)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

이 맥에 Developer ID가 있으면 그걸로, 없으면 `Scripts/make-signing-identity.sh`로 만든 로컬 인증서로(다시 빌드해도 위치 권한이 유지돼요), 그것도 없으면 ad-hoc으로 서명해요. `melatonin`이라는 notarytool 키체인 프로필이 있으면 `make package`가 공증까지 해요. 직접 가진 Developer ID로 서명하려면 `SIGN_IDENTITY`를 지정하세요.

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

번역을 추가하거나 고쳤다면 `python3 Scripts/check-localizations.py`로 빠진 문구와 자리표시자를 확인하세요.

## 로드맵

- [x] 서명·공증된 릴리스와 Homebrew cask
- [x] 연결 유지: 저장된 네트워크에 내가 정한 순서대로 연결
- [x] 돌아왔을 때 "자리 비운 사이" 요약
- [x] Sparkle 자동 업데이트
- [x] Claude Code·Codex 대화 기록으로 턴의 시작과 끝을 감지

## 라이선스

[MIT](LICENSE)
