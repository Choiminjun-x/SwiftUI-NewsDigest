# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**NewsDigest** is an iOS news reader app built with SwiftUI and modern Swift concurrency (async/await). It fetches headlines from [NewsAPI.org](https://newsapi.org) and supports search and favorites.

## Build & Run

This is a pure Xcode project with no external package manager.

```bash
# Open in Xcode
xed NewsDigest.xcodeproj

# Build from CLI
xcodebuild -project NewsDigest.xcodeproj -scheme NewsDigest build

# Run tests (if added)
xcodebuild test -project NewsDigest.xcodeproj -scheme NewsDigest -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Requirement:** `NEWS_API_KEY` must be set in `NewsDigest/Info/Info.plist`.

- **Swift:** 5.0
- **iOS Deployment Target:** 16.0+
- **No external dependencies** — only built-in Apple frameworks (SwiftUI, Combine, Foundation)

## Architecture

Strict **MVVM** with SwiftUI-first, state-driven UI.

```
NewsDigest/
├── NewsDigestApp.swift         # App entry point
├── ContentView.swift           # ⚠️ Legacy placeholder — unused, do not modify
├── NewsListView.swift          # Main screen: list, search, navigation
├── NewsDetailView.swift        # Article detail
├── NewsRowView.swift           # Reusable list row component
├── NewsViewModel.swift         # Central ViewModel + Article domain model
├── SettingsView.swift          # Settings screen
├── Networking/
│   ├── NewsService.swift       # Protocol-based API client (URLSession)
│   └── NewsAPIModels.swift     # Codable API response models + domainModel mapping
├── Support/
│   ├── Bundle+Secrets.swift    # Reads NEWS_API_KEY from Info.plist
│   └── FavoritesStore.swift    # FavoriteItem persistence model + UserDefaults store
└── Info/Info.plist             # App config including API key entry
```

### Key Patterns

**Navigation:** `NavigationStack` with a `Route` enum and `[Route]` path array in the View layer. ViewModel never touches navigation state.

```swift
enum Route: Hashable {
    case detail(Article)
    case settings
}
@State var path: [Route] = []
// Push: path.append(.detail(article))
```

**ViewModel:** All ViewModels are `@MainActor final class` conforming to `ObservableObject`. `@Published` properties default to `private(set)`.

**Concurrency:** async/await only. Use `.task {}` for lifecycle async work, not `.onAppear { Task { ... } }`. Avoid detached tasks. Respect cancellation.

**Services:** Protocol-driven for testability (`NewsService` protocol → `LiveNewsService`, `FavoritesStore` protocol → `UserDefaultsFavoritesStore`).

**Data models:** Two separate model layers — `NewsAPIArticle` (API/Codable, in `NewsAPIModels.swift`) maps to `Article` (domain, in `NewsViewModel.swift`) via `domainModel`. `FavoriteItem` (Codable, in `FavoritesStore.swift`) is the persistence model that also converts to `Article` via `asArticle`. `Article.id` is the article URL string if available, falling back to `"\(title)#\(author)"`.

**Child view navigation:** `NewsDetailView` and `SettingsView` receive an `onPopToRoot: () -> Void` callback rather than mutating the nav path directly.

**Search:** Debounced 350 ms via `Task.sleep` in `NewsListView`. The in-flight task is stored in `@State var searchTask` and cancelled on each keystroke.

**Combine:** `FavoritesStore.itemsPublisher` (`AnyPublisher<[FavoriteItem], Never>`) is intentionally bridged to `objectWillChange` in `NewsViewModel` — this is the one sanctioned Combine usage. All other async work uses async/await.

**Error handling:** Explicit `isLoading` and `errorMessage` states in ViewModel. No silent error ignoring, no force unwraps.

## Rules (from AGENTS.md)

### Forbidden Patterns
- UIKit usage (unless explicitly required)
- Force unwrap (`!`)
- Business logic inside Views
- NavigationStack path mutation inside ViewModel
- Unstable `Identifiable` IDs (e.g., computed UUID per access)
- Global mutable state without `EnvironmentObject`
- Mixing Combine and async/await without reason (the `FavoritesStore → objectWillChange` bridge is the one intentional exception)

### Code Style
- ViewModel naming: `FeatureNameViewModel`
- Route enum naming: `FeatureRoute`
- Keep Views under 150 lines; extract subviews when needed
- Use `// MARK:` comments to separate sections
- Prefer `struct` for Views, `final class` for ViewModels

### List & Rendering
- Models in `List` must conform to `Identifiable` with stable IDs
- No async calls inside row views
- No heavy computation in View body
- Avoid `AnyView` unless strictly necessary
