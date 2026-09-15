<p align="center"><img src="../../docs/assets/mailpilot-banner.svg" alt="MailPilot" width="100%" /></p>

<h1 align="center">MailPilot</h1>
<p align="center">AI 대화, 이메일 읽기와 답장을 하나의 Android 앱에서.</p>
<p align="center"><a href="https://github.com/dongfangshiwen/MailPilot/releases/latest">1.0.0 다운로드</a> · <a href="#quick-start">빠른 시작</a> · <a href="#build">배포 및 빌드</a></p>

[简体中文](../../README.md) · [繁體中文](../../docs/readme/README.zh-Hant.md) · [English](../../docs/readme/README.en.md) · [日本語](../../docs/readme/README.ja.md) · **한국어** · [Español](../../docs/readme/README.es.md) · [Français](../../docs/readme/README.fr.md) · [Deutsch](../../docs/readme/README.de.md)

> **Android 8.0+ · Flutter + Kotlin · 8 개 인터페이스 언어**<br>
> 사용할 모델을 설정하면 바로 대화할 수 있습니다. 이메일 계정은 필요할 때 추가하세요. 설정한 서비스에 직접 연결하므로 별도의 MailPilot 서버가 필요 없습니다. 이메일은 사용자가 확인한 후에만 전송됩니다.

## 주요 기능

| 기능 | 활용 방법 |
| --- | --- |
| **AI 대화** | Markdown 스트리밍, 접을 수 있는 사고·처리 과정, 모델 전환, 중지 및 재시도. |
| **이메일 도우미** | IMAP / SMTP 연결, 이메일 검색·읽기, 선택한 본문과 첨부 파일 분석. |
| **이미지와 문서** | 이미지, PDF, Office, 텍스트 지원. 같은 대화에서 완료된 이미지 분석을 재사용하거나 다시 확인. |
| **검색과 출처** | 설정한 검색 서비스로 공개 정보를 찾고, 자료의 웹 링크를 필요할 때 읽으며 인용 출처 확인. |
| **초안과 전송** | 답변을 이메일로 바꾸고 수신자·첨부를 편집한 뒤 확인 카드에서 검토하고 전송. |
| **대화 관리** | 검색, 날짜별 분류, 고정, 이름 변경, 사이드바 다중 선택. 긴 대화를 요약해도 원본 기록 보존. |
| **환경 설정** | 8개 언어, 밝은·어두운 테마, 음성 입력, 하루 간격을 포함한 선택적 백그라운드 동기화. |

## 화면 미리 보기

<p align="center">
  <img src="../../docs/screenshots/build43/language-zh-settings.png" width="30%" alt="简体中文" />
  <img src="../../docs/screenshots/build43/language-en-settings.png" width="30%" alt="English" />
  <img src="../../docs/screenshots/build43/language-de-settings.png" width="30%" alt="Deutsch — dark theme" />
</p>

중국어 간체, 영어, 독일어 다크 모드 설정 화면입니다. 실제 계정 인증 정보가 아닌 예시 설정을 사용했습니다.

<a id="quick-start"></a>
## 빠른 시작

1. **설치**: 위 Releases에서 APK를 받으세요. 기존 설치를 업데이트하려면 같은 서명의 패키지를 사용해 데이터를 유지하세요.
2. **모델 추가**: 설정 → 모델 및 서비스 → 모델 추가에서 제공업체, HTTPS Base URL, 모델 이름, API 키를 입력하세요. DeepSeek, 화산방주, Alibaba Cloud Model Studio 및 호환 API를 설정할 수 있으며 기능은 모델에 따라 달라집니다.
3. **대화 시작**: 홈에서 질문하거나 ＋ 버튼으로 이미지와 파일을 추가하세요. AI 대화에는 이메일 계정이 필요하지 않습니다.
4. **이메일 연결(선택)**: 설정의 이메일 계정에서 QQ, 163, Alibaba Mail 또는 사용자 지정 IMAP / SMTP를 추가하세요. 제공업체에서 서비스를 활성화하고 인증 코드나 앱 비밀번호를 사용하세요.
5. **읽기와 답장**: 설정에서 내 이메일을 열어 동기화하세요. 대화의 ＋에서 이메일과 첨부 범위를 선택한 다음 분석이나 초안 작성을 요청하세요. 수신자, 본문, 첨부를 확인한 후 전송하세요.
6. **맞춤 설정**: 검색·음성 서비스, 언어, 테마, 동기화를 설정하세요. 기본 언어는 중국어 간체입니다. 인터페이스 언어를 바꿔도 이메일과 모델 답변이 자동 번역되지는 않습니다.

### 이렇게 질문해 보세요

- “선택한 이메일을 요약하고 납기, 금액, 확인할 사항을 정리해 줘.”
- “이 이미지들의 규격 차이를 비교하고 출처를 표시해 줘.”
- “이 결론으로 영어 답장을 작성하고 먼저 검토하게 해 줘.”

### 첨부 파일 지원

| 형식 | 처리 방법 |
| --- | --- |
| JPG / PNG / WebP | 설정한 비전 모델로 분석 |
| PDF | 선택한 페이지를 이미지로 렌더링, 기본 앞 10페이지 |
| DOCX / XLSX / PPTX | 텍스트·표·포함된 이미지를 기기에서 추출 |
| TXT | 기기에서 읽기. 기존 DOC / XLS / PPT는 먼저 변환 |

한 번에 첨부 10개, 총 50 MB, 시각 자료 20개까지이며 개별 첨부는 20 MB까지입니다. 인코딩한 요청에는 앱의 32 MiB 제한과 제공업체 제한도 적용됩니다. 초과하면 자료를 조정하거나 분할 처리를 선택하세요.

<a id="build"></a>
## 배포 및 빌드

Android에서 실행되며 Docker, 데이터베이스 서버, 별도 API 백엔드가 필요하지 않습니다. 인증 정보는 소스 코드가 아닌 앱 설정에 입력하세요. Web은 예시 UI 미리 보기 전용입니다.

### 빌드 환경

| 구성 요소 | 검증 버전 |
| --- | --- |
| Flutter / Dart | 3.47.2 / 3.13.2 |
| JDK | 17–25 |
| Android SDK / Build Tools | 36 / 36.0.0 |
| NDK / CMake | 28.2.13676358 / 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0 |

Flutter와 Android Studio를 설치하고 Flutter를 PATH에 추가하세요. SDK Manager에서 아래 Android 구성 요소를 설치하고 JDK 경로를 실제 설치 위치로 바꾸세요. 최초 의존성 다운로드에는 인터넷이 필요합니다.

```powershell
git clone https://github.com/dongfangshiwen/MailPilot.git
cd MailPilot
flutter doctor

$env:MAILPILOT_JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\scripts\Build.ps1 -Mode Debug
.\scripts\Build.ps1 -Mode Release
.\scripts\Package-Delivery.ps1
```

Debug는 격리 패키지 `app.mailpilot.validation`, Release는 `app.mailpilot`을 사용합니다. 스크립트가 로컬 SDK 설정을 생성합니다. 첫 Release 빌드의 `.signing/`을 향후 업데이트를 위해 보관하세요. 새로 만든 키로는 공식 서명 버전을 덮어쓸 수 없습니다.

### 출력 파일 · artifacts/

| 파일 | 용도 |
| --- | --- |
| `MailPilot-1.0.0-flutter-release.apk` | Android 설치 파일 |
| `MailPilot-1.0.0-flutter-source.zip` | 소스·스크립트·문서·스크린샷 |
| `MailPilot-1.0.0-flutter-delivery.zip` | APK와 소스 전체 패키지 |
| `*.sha256` | 해당 파일의 SHA-256 체크섬 |

### 테스트

```powershell
.\scripts\Build.ps1 -Mode Test
adb devices
.\scripts\Test-Profile.ps1 -Device emulator-5554 -Mode Debug -Target integration_test/language43_test.dart
```

기기 ID를 `adb devices`에 표시된 값으로 바꾸세요. UI 테스트는 격리 패키지를 사용하고 앱을 유지합니다. 평소 사용하는 패키지에서 `flutter drive`를 직접 실행하지 마세요.

언어 업데이트는 Flutter 테스트 489개, 네이티브 언어 테스트 3개, API36 격리 검증을 통과했습니다. Lint 오류는 0개, 권고 사항은 13개입니다. 72개 레이아웃 사례로 8개 언어, 3개 화면 너비, 글자 배율을 확인했습니다.

### 브라우저 미리 보기

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

예시 이메일과 모의 응답을 사용하며 실제 이메일이나 모델 서비스에 연결하지 않습니다. Web 이메일 클라이언트 지원을 뜻하지 않습니다.

## 프로젝트 구조

```text
MailPilot/
├── lib/                    # Flutter UI
│   └── l10n/               # ARB resources & generated localizations
├── android/app/src/main/   # Android services & Agent
├── test/                   # Flutter tests
├── integration_test/       # Isolated UI tests
├── scripts/                # Windows build & packaging
└── docs/                   # Guides, reports & screenshots
```

Flutter가 UI를 담당하고 플랫폼 채널로 Kotlin 서비스를 호출합니다. Android는 Agent, 이메일, 첨부, Room, DataStore를 처리합니다. `lib/l10n/`의 ARB를 수정한 후 `flutter gen-l10n`을 실행하세요.

## 데이터와 전송

- 인증 코드와 API 키는 Android Keystore로 암호화하며 대화·첨부·캐시는 앱 전용 저장소에 보관합니다.
- 질문할 때 선택한 자료를 설정된 모델에 전송합니다. 검색·클라우드 음성은 해당 서비스를 사용하며 제공업체 요금이 발생할 수 있습니다.
- 웹 읽기는 읽기 전용입니다. 로그인, CAPTCHA, 일부 동적 사이트는 읽을 수 없으며 모든 링크의 추출을 보장하지 않습니다.
- 이메일 전송에는 항상 사용자 확인이 필요합니다. 백그라운드 동기화는 기본적으로 꺼져 있고 자동 분석이나 전송을 하지 않습니다.
- 앱 삭제 시 로컬 데이터가 지워집니다. 배포 파일에는 서명 키, 사용자 설정, 데이터베이스가 없습니다. 개발자는 `.signing/`을 별도로 백업하세요.

## 더 알아보기

- [이메일 설정 안내](../../docs/MAIL_SETUP.md)
- [8개 언어 및 테스트 보고서](../../docs/LOCALIZATION_1_0_0_BUILD_43.md)
- [변경 이력](../../docs/CHANGELOG.md)
- [타사 구성 요소](../../docs/THIRD_PARTY.md)

README는 8개 언어로 제공하며 상세 기술 기록은 주로 중국어 간체로 작성되어 있습니다.
