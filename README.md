# NewsDigest

> SwiftUI 학습 목적의 iOS 뉴스 리더 앱 | iOS 16+ / Swift 5.0

<p align="center">
  <img src="https://github.com/user-attachments/assets/d2e376ca-d5d7-45ee-9801-874ffbf7d6ca" width="22%" />
  <img src="https://github.com/user-attachments/assets/30f0f2c9-0762-46d6-b2c3-fe5995bc91b1" width="22%" />
  <img src="https://github.com/user-attachments/assets/e2d31d03-e3a6-4a52-8b63-040e2f4d92c6" width="22%" />
  <img src="https://github.com/user-attachments/assets/cc5af62e-cf57-4c6c-a012-417b18dbc8e8" width="22%" />
</p>

---

## 1. 개요

> NewsAPI.org에서 실시간 헤드라인을 가져와 검색·즐겨찾기를 지원하는 SwiftUI 기반 뉴스 리더

SwiftUI의 상태 관리, NavigationStack, async/await, 프로토콜 기반 설계를 실제 앱에 적용해보기 위한 프로젝트.

**주요 기능**

- 실시간 뉴스 헤드라인 조회 (NewsAPI.org)
- 키워드 검색 — 입력 후 350ms 디바운스 적용
- 스와이프 액션으로 즐겨찾기 추가 / 해제
- 즐겨찾기 앱 재시작 후에도 유지 (UserDefaults)
- Pull to Refresh

---

## 2. 아키텍처

> 엄격한 MVVM — View는 상태를 표시하고 이벤트를 전달하는 역할만 담당

```
View (SwiftUI)
  └─ NewsListView / NewsDetailView / SettingsView
       │  상태 구독 + 사용자 이벤트 전달
       ▼
ViewModel (@MainActor, ObservableObject)
  └─ NewsViewModel
       │  비즈니스 로직, 로딩/에러 상태 관리
       ▼
Service / Store (Protocol 기반)
  ├─ LiveNewsService              ← URLSession으로 NewsAPI 호출
  └─ UserDefaultsFavoritesStore   ← 즐겨찾기 영속성
```

**레이어별 책임**

| 레이어 | 구현체 | 책임 |
|---|---|---|
| View | `NewsListView` 등 | 상태 렌더링, 이벤트 전달 |
| ViewModel | `NewsViewModel` | 비즈니스 로직, 상태 노출 |
| Service | `LiveNewsService` | API 호출, 응답 파싱 |
| Store | `UserDefaultsFavoritesStore` | 즐겨찾기 영속성 |

**프로젝트 구조**

```
NewsDigest/
├── NewsDigestApp.swift         # 앱 진입점
├── NewsListView.swift          # 메인 화면 (목록, 검색, 네비게이션)
├── NewsDetailView.swift        # 기사 상세 화면
├── NewsRowView.swift           # 목록 행 컴포넌트
├── NewsViewModel.swift         # ViewModel + Article 도메인 모델
├── SettingsView.swift          # 설정 화면
├── Networking/
│   ├── NewsService.swift       # API 클라이언트 프로토콜
│   └── NewsAPIModels.swift     # API 응답 모델 (Codable)
├── Support/
│   ├── Bundle+Secrets.swift    # Info.plist에서 API 키 로드
│   └── FavoritesStore.swift    # 즐겨찾기 저장소
└── Info/Info.plist             # API 키 설정 포함
```

---

## 3. 기술 스택

| 분류 | 내용 |
|---|---|
| UI | SwiftUI |
| 아키텍처 | MVVM |
| 비동기 처리 | Swift Concurrency (async/await) |
| 상태 관리 | `ObservableObject`, `@Published` |
| 네트워킹 | URLSession |
| 데이터 파싱 | Codable, JSONDecoder |
| 영속성 | UserDefaults |
| 반응형 | Combine (publisher 브릿지 한정) |
| 외부 API | [NewsAPI.org](https://newsapi.org) |
| 개발 환경 | Xcode 15+, iOS 16.0+, Swift 5.0 |
| 외부 패키지 | 없음 |

---

## 4. 시작하기

**사전 조건**

- Xcode 15 이상
- [NewsAPI.org](https://newsapi.org)에서 무료 API 키 발급

**API 키 설정**

`NewsDigest/Info/Info.plist`에 아래 항목 추가:

```xml
<key>NEWS_API_KEY</key>
<string>여기에_발급받은_키_입력</string>
```

**빌드 및 실행**

```bash
# Xcode에서 열기
xed NewsDigest.xcodeproj

# CLI 빌드
xcodebuild -project NewsDigest.xcodeproj -scheme NewsDigest build
```

Xcode에서 시뮬레이터 또는 실기기 선택 후 `Cmd + R`.

---

## 5. 핵심 패턴 & 주의사항

**NavigationStack with Route enum**

```swift
enum Route: Hashable {
    case detail(Article)
    case settings
}
@State var path: [Route] = []
// 화면 전환
path.append(.detail(article))
```

**검색 디바운스**

```swift
// 키 입력마다 이전 Task 취소 후 재생성
searchTask?.cancel()
searchTask = Task {
    try? await Task.sleep(nanoseconds: 350_000_000)
    guard !Task.isCancelled else { return }
    await viewModel.search(query: query)
}
```

**Combine ↔ async/await 브릿지**

```swift
// FavoritesStore.itemsPublisher → objectWillChange 브릿지 (유일하게 허용된 Combine 사용)
favoritesStore.itemsPublisher
    .sink { [weak self] _ in self?.objectWillChange.send() }
    .store(in: &cancellables)
```

**Good / Bad 패턴**

| | 패턴 | 이유 |
|---|---|---|
| ✅ | `.task {}` modifier 사용 | View 라이프사이클에 맞춰 자동 취소 |
| ✅ | `Article.id`를 URL 기반으로 고정 | List 렌더링 시 안정적인 Identifiable |
| ✅ | Service를 프로토콜로 추상화 | 테스트 시 Mock 교체 가능 |
| ❌ | `.onAppear { Task { ... } }` | 취소 불가, 중복 실행 위험 |
| ❌ | ViewModel에서 NavigationStack path 조작 | 레이어 책임 위반 |
| ❌ | Force unwrap (`!`) | 런타임 크래시 위험 |
| ❌ | View body 안에서 무거운 연산 | 렌더링 성능 저하 |

> API 키는 절대 커밋 금지 — `.gitignore`에 `Info.plist`를 추가하거나 키 값을 로컬에서만 관리.

---

## 6. 학습 포인트

| 주제 | 핵심 내용 |
|---|---|
| SwiftUI 상태 관리 | `@State` / `@StateObject` / `@Published` 역할 분리 |
| NavigationStack | `Route` enum으로 타입 안전한 화면 전환 |
| async/await | `.task {}`, `Task.cancel()`, `CancellationError` 처리 |
| 프로토콜 기반 설계 | Service/Store 추상화로 느슨한 의존성 연결 |
| Codable + API 연동 | API 응답 모델과 도메인 모델 분리 (`NewsAPIArticle` → `Article`) |
