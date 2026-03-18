# SwiftUI 학습 노트 — NewsDigest 프로젝트 복기용

> 이 문서는 NewsDigest 프로젝트를 통해 학습한 SwiftUI 핵심 개념을 상세히 정리한 복기용 노트입니다.

---

## 목차

1. [SwiftUI 상태 관리](#1-swiftui-상태-관리)
2. [NavigationStack](#2-navigationstack)
3. [async/await 비동기 처리](#3-asyncawait-비동기-처리)
4. [프로토콜 기반 설계](#4-프로토콜-기반-설계)
5. [List와 Identifiable](#5-list와-identifiable)
6. [Codable과 API 연동](#6-codable과-api-연동)

---

## 1. SwiftUI 상태 관리

### @State

View가 **직접 소유**하는 단순 값 타입(String, Bool, Int 등)에 사용합니다.
SwiftUI가 해당 값을 메모리에서 관리하고, 값이 바뀌면 자동으로 View를 다시 그립니다.

```swift
// NewsListView.swift
@State private var searchText: String = ""
@State private var showError: Bool = false
@State private var path: [Route] = []
```

- `private`으로 선언하는 것이 원칙 — 외부에서 직접 수정하지 않음
- View 구조체는 매번 새로 만들어지지만, `@State` 값은 SwiftUI가 별도로 유지해 줌
- **값 타입(struct)에만 사용** — 클래스 객체에는 사용하지 않음

---

### @StateObject

View가 **직접 생성하고 소유**하는 참조 타입(`ObservableObject`)에 사용합니다.

```swift
// NewsListView.swift
@StateObject private var viewModel = NewsViewModel()
```

- View가 처음 생성될 때 딱 한 번 인스턴스를 만들고, 이후 View가 다시 그려져도 **인스턴스를 새로 만들지 않음**
- 만약 `@ObservedObject`를 썼다면 부모 View가 다시 그려질 때마다 ViewModel이 새로 생성되어 상태가 초기화되는 버그 발생 가능

> **@StateObject vs @ObservedObject 차이**
> | | @StateObject | @ObservedObject |
> |---|---|---|
> | 소유권 | 이 View가 생성하고 소유 | 외부에서 주입받음 |
> | 생명주기 | View와 동일하게 유지 | 주입한 쪽에서 관리 |
> | 사용 시점 | ViewModel을 처음 만드는 곳 | 부모에게서 받아 쓰는 곳 |

---

### @Published

`ObservableObject` 클래스 내부에서 **변경을 외부에 알리고 싶은 프로퍼티**에 붙입니다.

```swift
// NewsViewModel.swift
@Published private(set) var articles: [Article] = []
@Published private(set) var isLoading: Bool = false
@Published private(set) var errorMessage: String?
```

- 값이 바뀌는 순간 `objectWillChange` 이벤트가 자동 발행됨
- 이를 구독 중인 View(`@StateObject`, `@ObservedObject`)가 자동으로 다시 그려짐
- `private(set)` — 외부에서 읽기는 가능하지만 **쓰기는 ViewModel 내부에서만** 가능하도록 제한

---

### 상태 변화 → View 업데이트 흐름 요약

```
사용자 액션 (버튼 탭, 스크롤 등)
    │
    ▼
View가 ViewModel의 메서드 호출
    │
    ▼
ViewModel 내부 @Published 프로퍼티 값 변경
    │
    ▼
objectWillChange 자동 발행
    │
    ▼
SwiftUI가 변경 감지 → View body 재실행 → 화면 업데이트
```

---

## 2. NavigationStack

### NavigationView vs NavigationStack

iOS 16 이전에는 `NavigationView`를 사용했으나, iOS 16부터 `NavigationStack`으로 대체되었습니다.

| | NavigationView (구) | NavigationStack (신) |
|---|---|---|
| 도입 | iOS 13 | iOS 16 |
| 경로 관리 | 내부적으로 관리, 직접 접근 어려움 | `path` 배열로 직접 제어 |
| 딥링크 | 구현 복잡 | path 배열 조작으로 간단히 가능 |
| 타입 안전성 | `NavigationLink(destination:)` — 컴파일 타임 확인 어려움 | `navigationDestination(for:)` — 타입 기반, 안전 |

---

### Route enum과 타입 안전 내비게이션

화면 전환 대상을 `enum`으로 정의하면 **어떤 화면으로 이동할 수 있는지 컴파일 타임에 명확히** 확인할 수 있습니다.

```swift
// NewsListView.swift
enum Route: Hashable {
    case detail(Article)  // 연관값으로 데이터를 함께 전달
    case settings
}
```

`Hashable`을 채택해야 `NavigationStack`의 path 배열 요소로 사용할 수 있습니다.
`Article`이 `Hashable`을 채택한 것도 이 때문입니다.

---

### NavigationStack 사용 패턴

```swift
// path 배열로 현재 내비게이션 스택을 직접 제어
@State private var path: [Route] = []

NavigationStack(path: $path) {
    // 루트 화면 내용
    content
        .navigationDestination(for: Route.self) { route in
            // route 값에 따라 어떤 View를 보여줄지 결정
            destination(for: route)
        }
}

// 화면 이동 — path에 추가
path.append(.detail(article))   // detail 화면으로 이동
path.append(.settings)          // settings 화면으로 이동

// 화면 복귀
path.removeLast()               // 한 단계 뒤로
path.removeAll()                // 루트로 바로 이동
```

---

### ViewModel은 path를 건드리지 않는다

MVVM에서 내비게이션 상태(`path`)는 **View의 책임**입니다.
ViewModel이 path를 직접 수정하면 View와 ViewModel이 강하게 결합되어 재사용과 테스트가 어려워집니다.

```swift
// ✅ 올바른 패턴 — View에서 path 조작
Button { path.append(.settings) } label: { ... }

// ❌ 잘못된 패턴 — ViewModel에서 path 참조
// viewModel.path.append(.settings)  // ViewModel이 View 상태를 알면 안 됨
```

---

### onPopToRoot 콜백 패턴

자식 View(Detail, Settings)가 루트로 돌아가야 할 때, 직접 path를 갖지 않고
**부모에게서 클로저를 받아 실행**합니다.

```swift
// NewsDetailView — path를 모르지만 루트로 돌아갈 수 있음
struct NewsDetailView: View {
    let article: Article
    let onPopToRoot: () -> Void  // 부모가 주입
    ...
}

// 부모(NewsListView)에서 실제 동작 정의
NewsDetailView(article: article) {
    path.removeAll()  // 여기서 path를 조작
}
```

---

## 3. async/await 비동기 처리

### 기존 방식의 문제점

```swift
// ❌ 과거 콜백 방식 — 콜백 지옥, 에러 처리 복잡
URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error { ... }
    // 또 다른 비동기 작업이 있으면 중첩이 계속됨
    DispatchQueue.main.async {
        self.articles = parsed
    }
}.resume()
```

```swift
// ✅ async/await — 동기 코드처럼 읽히고, 에러도 throws로 자연스럽게 처리
func loadTopHeadlines() async {
    let items = try await service.topHeadlines(...)
    articles = items
}
```

---

### .task {} modifier

View가 화면에 나타날 때 비동기 작업을 시작하고,
View가 사라지면 자동으로 해당 Task를 **취소**해줍니다.

```swift
// NewsListView.swift
.task { await viewModel.loadTopHeadlines() }
```

- `.onAppear { Task { ... } }` 보다 선호 — onAppear는 View가 사라져도 Task가 계속 실행됨
- View의 생명주기와 Task의 생명주기가 자동으로 연동됨

---

### Task와 취소 (Cancellation)

검색어를 빠르게 타이핑할 때 매 글자마다 API를 호출하면 불필요한 요청이 많이 발생합니다.
**디바운스**: 마지막 입력 후 일정 시간이 지났을 때만 실제 요청을 실행하는 패턴입니다.

```swift
// NewsListView.swift
@State private var searchTask: Task<Void, Never>? = nil

.onChange(of: searchText) { newValue in
    searchTask?.cancel()           // 이전에 대기 중이던 Task 취소
    searchTask = Task { [newValue] in
        try? await Task.sleep(nanoseconds: 350_000_000)  // 350ms 대기
        if Task.isCancelled { return }                    // 취소됐으면 중단
        await viewModel.loadTopHeadlines(query: newValue.isEmpty ? nil : newValue)
    }
}
```

흐름:
1. 'S' 입력 → Task A 생성 (350ms 대기 시작)
2. 'Sw' 입력 → Task A 취소, Task B 생성 (350ms 재시작)
3. 350ms 동안 추가 입력 없음 → Task B 실행 → API 호출 1회

---

### CancellationError 처리

Task가 취소되면 `await` 지점에서 `CancellationError`가 던져집니다.
이를 일반 에러와 같이 처리하면 사용자에게 불필요한 에러 알럿이 표시됩니다.

```swift
// NewsViewModel.swift
} catch is CancellationError {
    // 사용자가 직접 유발한 취소 — 조용히 무시
    return
} catch {
    // 실제 네트워크/서버 에러만 사용자에게 알림
    errorMessage = error.localizedDescription
}
```

---

### @MainActor

UI 업데이트는 반드시 **메인 스레드**에서 일어나야 합니다.
`@MainActor`를 클래스에 붙이면 해당 클래스의 모든 메서드와 프로퍼티 접근이 자동으로 메인 스레드에서 실행됩니다.

```swift
// NewsViewModel.swift
@MainActor
final class NewsViewModel: ObservableObject {
    @Published private(set) var articles: [Article] = []  // 메인 스레드 보장
    ...
}
```

- 별도로 `DispatchQueue.main.async { ... }` 를 쓸 필요가 없음
- 백그라운드에서 데이터를 받아와도 `@Published` 프로퍼티 업데이트 시 자동으로 메인 스레드로 전환

---

## 4. 프로토콜 기반 설계

### 왜 프로토콜로 추상화하는가

```swift
// ❌ 구체 타입 직접 의존
final class NewsViewModel {
    private let service = LiveNewsService()  // LiveNewsService에 강하게 묶임
}
```

위 방식은 테스트할 때 실제 네트워크 요청이 발생하고, 다른 구현체로 교체하기 어렵습니다.

```swift
// ✅ 프로토콜 의존
final class NewsViewModel {
    private let service: NewsService  // 프로토콜 타입으로 받음

    init(service: NewsService = LiveNewsService()) {
        self.service = service
    }
}
```

이렇게 하면:
- 테스트 시 `MockNewsService`를 주입해 네트워크 없이 테스트 가능
- 나중에 다른 뉴스 API로 교체해도 ViewModel 코드를 수정할 필요 없음

---

### 이 프로젝트의 프로토콜 구조

```
NewsService (protocol)
  └─ topHeadlines(country:query:page:pageSize:) async throws -> [Article]
        │
        ├─ LiveNewsService (실제 구현 — URLSession으로 NewsAPI 호출)
        └─ MockNewsService (테스트용 — 고정된 더미 데이터 반환)

FavoritesStore (protocol)
  └─ items, isFavorited(), toggle(), itemsPublisher
        │
        ├─ UserDefaultsFavoritesStore (실제 구현 — UserDefaults에 저장)
        └─ InMemoryFavoritesStore (테스트용 — 메모리에만 저장)
```

---

### 기본값을 이용한 편의 초기화

```swift
// 기본값으로 실제 구현체를 사용하되, 주입도 허용
init(service: NewsService = LiveNewsService(),
     favoritesStore: FavoritesStore = UserDefaultsFavoritesStore()) {
    self.service = service
    self.favoritesStore = favoritesStore
}

// 앱에서는 기본값 사용
let vm = NewsViewModel()

// 테스트에서는 Mock 주입
let vm = NewsViewModel(service: MockNewsService(), favoritesStore: MockFavoritesStore())
```

---

## 5. List와 Identifiable

### Identifiable이란

`List`나 `ForEach`가 각 항목을 **구별하기 위해** 사용하는 프로토콜입니다.
SwiftUI는 `id`를 기준으로 어떤 항목이 추가/삭제/변경되었는지 파악하고 최소한의 업데이트만 수행합니다.

```swift
protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}
```

---

### 안정적인 ID의 중요성

```swift
// ❌ 불안정한 ID — 접근할 때마다 새 UUID 생성
struct Article: Identifiable {
    var id: UUID { UUID() }  // 매번 달라짐 → List가 항목을 제대로 추적 못함
}
```

ID가 매번 바뀌면:
- 스크롤 위치가 튀거나 애니메이션이 깨짐
- 즐겨찾기 상태가 올바르게 반영되지 않음
- 불필요한 View 재생성으로 성능 저하

```swift
// ✅ 안정적인 ID — 동일한 기사는 항상 같은 ID
struct Article: Identifiable {
    let id: String  // 한 번 생성되면 변하지 않음
}
```

---

### stableID 전략

뉴스 기사를 고유하게 식별하는 가장 신뢰할 수 있는 값은 **URL**입니다.
URL이 없는 경우(드문 케이스)를 대비한 폴백도 준비합니다.

```swift
// NewsViewModel.swift
static func stableID(url: URL?, title: String, author: String) -> String {
    // 1순위: URL (가장 고유함)
    if let u = url?.absoluteString, !u.isEmpty { return u }
    // 2순위: 제목 + 저자 조합 (URL이 없는 경우 폴백)
    return "\(title)#\(author)"
}
```

---

## 6. Codable과 API 연동

### Codable이란

`Encodable + Decodable`을 합친 프로토콜입니다.
채택하면 JSON ↔ Swift 구조체 변환을 자동으로 처리해줍니다.

```swift
struct NewsAPIArticle: Codable {
    let author: String?
    let title: String?
    let url: URL?
    let publishedAt: Date?
    ...
}

// JSON → Swift
let article = try JSONDecoder().decode(NewsAPIArticle.self, from: jsonData)

// Swift → JSON
let data = try JSONEncoder().encode(article)
```

---

### API 응답 모델 vs 도메인 모델 분리

외부 API의 응답 구조와 앱 내부에서 사용하는 데이터 구조를 **분리**합니다.

```
NewsAPIArticle (API 응답 모델)     Article (앱 도메인 모델)
─────────────────────────          ──────────────────────
source: Source?                    id: String  ← stableID
author: String?           →→→      title: String
title: String?          domainModel description: String
description: String?               author: String
url: URL?                          url: URL?
urlToImage: URL?
publishedAt: Date?
content: String?
```

**이유:**
- API 응답에는 앱에서 불필요한 필드가 많고, 모든 값이 `Optional`
- 도메인 모델은 앱 로직에 필요한 것만 담고, 가능한 한 `non-Optional`로 정리
- API 스펙이 바뀌어도 `domainModel` 변환 부분만 수정하면 나머지 코드는 영향 없음

```swift
// NewsAPIModels.swift
extension NewsAPIArticle {
    var domainModel: Article {
        Article(
            title: title ?? source?.name ?? "Untitled",  // nil 처리를 여기서 해결
            description: description ?? content ?? "",
            author: author ?? "Unknown",
            url: url
        )
    }
}
```

---

### JSONDecoder 커스터마이징

API마다 날짜 형식이 다를 수 있습니다.
`JSONDecoder`의 `dateDecodingStrategy`를 커스터마이징하면 다양한 형식을 처리할 수 있습니다.

```swift
// NewsService.swift
static let news: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .custom { decoder in
        let string = try decoder.singleValueContainer().decode(String.self)

        // 시도 1: 소수점 초 포함 ISO8601 (e.g. "2026-03-18T12:00:00.000Z")
        let isoFS = ISO8601DateFormatter()
        isoFS.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFS.date(from: string) { return date }

        // 시도 2: 일반 ISO8601 (e.g. "2026-03-18T12:00:00Z")
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: string) { return date }

        throw DecodingError.dataCorruptedError(...)
    }
    return d
}()
```

---

### 에러 처리 — LocalizedError

에러를 사용자에게 보여줄 때는 `LocalizedError`를 채택해 친절한 메시지를 제공합니다.

```swift
// NewsService.swift
enum NewsServiceError: LocalizedError {
    case missingAPIKey
    case badStatus(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API 키가 없습니다. Info.plist를 확인하세요."
        case .badStatus(let code): return "서버 오류: \(code)"
        case .decoding: return "데이터 파싱에 실패했습니다."
        }
    }
}
```

ViewModel에서는 `LocalizedError`를 먼저 확인하고, 없으면 기본 설명을 사용합니다.

```swift
// NewsViewModel.swift
errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
```
