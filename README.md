# NewsDigest

> SwiftUI 기초 학습을 목적으로 News Open API를 활용해 만든 iOS 뉴스 리더 앱입니다.
<img width="1170" height="2532" alt="IMG_0257" src="https://github.com/user-attachments/assets/d2e376ca-d5d7-45ee-9801-874ffbf7d6ca" />
<img width="1170" height="2532" alt="IMG_0258" src="https://github.com/user-attachments/assets/30f0f2c9-0762-46d6-b2c3-fe5995bc91b1" />
<img width="1170" height="2532" alt="IMG_0259" src="https://github.com/user-attachments/assets/e2d31d03-e3a6-4a52-8b63-040e2f4d92c6" />
<img width="1170" height="2532" alt="IMG_0260" src="https://github.com/user-attachments/assets/cc5af62e-cf57-4c6c-a012-417b18dbc8e8" />

---

## 주요 기능

- 실시간 뉴스 헤드라인 조회 (NewsAPI.org)
- 키워드 검색 (입력 후 350ms 디바운스 적용)
- 스와이프 액션으로 즐겨찾기 추가 / 해제
- 즐겨찾기 목록 앱 재시작 후에도 유지
- 당겨서 새로고침 (Pull to Refresh)

---

## 사용 기술

| 분류 | 내용 |
|---|---|
| UI | SwiftUI |
| 아키텍처 | MVVM |
| 비동기 처리 | Swift Concurrency (async/await) |
| 상태 관리 | ObservableObject, @Published |
| 네트워킹 | URLSession |
| 데이터 파싱 | Codable, JSONDecoder |
| 영속성 | UserDefaults |
| 반응형 | Combine (publisher 브릿지) |
| 외부 API | [NewsAPI.org](https://newsapi.org) |
| 개발 환경 | Xcode, iOS 16.0+ / Swift 5.0 |
| 외부 패키지 | 없음 (순수 Apple 프레임워크만 사용) |

---

## 아키텍처

MVVM 패턴을 기반으로 각 레이어의 역할을 명확히 분리했습니다.

```
View (SwiftUI)
  └─ NewsListView / NewsDetailView / SettingsView
       │  상태를 구독하고 사용자 이벤트를 전달
       ▼
ViewModel (@MainActor, ObservableObject)
  └─ NewsViewModel
       │  비즈니스 로직, 로딩/에러 상태 관리
       ▼
Service / Store (Protocol 기반)
  ├─ LiveNewsService    ← URLSession으로 NewsAPI 호출
  └─ UserDefaultsFavoritesStore  ← 즐겨찾기 영속성
```

- **View**는 상태를 표시하고 이벤트를 ViewModel에 전달하는 역할만 담당
- **ViewModel**은 `@Published` 프로퍼티로 상태를 노출하며, 네비게이션 스택을 직접 건드리지 않음
- **Service/Store**는 프로토콜로 정의되어 테스트 시 Mock으로 교체 가능

---

## 프로젝트 구조

```
NewsDigest/
├── NewsDigestApp.swift         # 앱 진입점
├── NewsListView.swift          # 메인 화면 (목록, 검색, 네비게이션)
├── NewsDetailView.swift        # 기사 상세 화면
├── NewsRowView.swift           # 목록 행 컴포넌트
├── NewsViewModel.swift         # ViewModel + Article 도메인 모델
├── SettingsView.swift          # 설정 화면
├── Networking/
│   ├── NewsService.swift       # API 클라이언트
│   └── NewsAPIModels.swift     # API 응답 모델 (Codable)
├── Support/
│   ├── Bundle+Secrets.swift    # API 키 로드
│   └── FavoritesStore.swift    # 즐겨찾기 저장소
└── Info/Info.plist             # API 키 설정 포함
```

---

## 시작하기

### 사전 조건

- Xcode 15 이상
- [NewsAPI.org](https://newsapi.org) 에서 무료 API 키 발급

### API 키 설정

`NewsDigest/Info/Info.plist` 파일에 아래 항목을 추가합니다.

```xml
<key>NEWS_API_KEY</key>
<string>여기에_발급받은_키_입력</string>
```

> API 키는 절대 커밋하지 마세요. `.gitignore`에 `Info.plist`를 추가하거나, 키 값을 로컬에서만 관리하세요.

### 빌드 및 실행

```bash
# Xcode에서 열기
xed NewsDigest.xcodeproj
```

Xcode에서 시뮬레이터 또는 실기기를 선택한 뒤 `Cmd + R`로 실행합니다.

---

## 학습 포인트

SwiftUI를 처음 공부하면서 이 프로젝트를 통해 직접 적용해본 개념들입니다.

**SwiftUI 상태 관리**
- `@State`, `@StateObject`, `@Published`의 차이와 역할
- ViewModel의 상태 변화가 View에 자동으로 반영되는 흐름 이해

**NavigationStack**
- iOS 16에서 도입된 `NavigationStack`과 `navigationDestination(for:)` 사용법
- `Route` enum으로 화면 전환을 타입 안전하게 관리하는 방법
- 이전 방식인 `NavigationView`와의 차이

**async/await 비동기 처리**
- `.task {}` modifier로 View 라이프사이클에 맞춰 비동기 작업 실행
- `Task.cancel()`을 활용한 검색 디바운스 구현
- `CancellationError` 처리로 불필요한 에러 알럿 방지

**프로토콜 기반 설계**
- Service와 Store를 프로토콜로 추상화해 의존성을 느슨하게 연결하는 방법
- 실제 구현체(`LiveNewsService`)와 인터페이스(`NewsService`)를 분리하는 이유

**List와 Identifiable**
- `List`에서 `Identifiable`의 `id`가 안정적이어야 하는 이유
- URL을 기반으로 안정적인 ID를 생성하는 `stableID` 전략

**Codable과 API 연동**
- `JSONDecoder`로 외부 API 응답을 Swift 구조체에 매핑하는 흐름
- API 응답 모델(`NewsAPIArticle`)과 앱 내부 도메인 모델(`Article`)을 분리하는 이유
