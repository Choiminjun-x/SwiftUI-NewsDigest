//
//  NewsViewModel.swift
//  NewsDigest
//
//  Created by 최민준(Minjun Choi) on 2/19/26.
//

import Foundation
import Combine

struct Article: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let author: String
    let url: URL?

    init(id: String, title: String, description: String, author: String, url: URL?) {
        self.id = id
        self.title = title
        self.description = description
        self.author = author
        self.url = url
    }

    init(title: String, description: String, author: String, url: URL? = nil) {
        self.id = Article.stableID(url: url, title: title, author: author)
        self.title = title
        self.description = description
        self.author = author
        self.url = url
    }

    static func stableID(url: URL?, title: String, author: String) -> String {
        if let u = url?.absoluteString, !u.isEmpty { return u }
        return "\(title)#\(author)" // fallback for provider without URL
    }
}

@MainActor
final class NewsViewModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var articles: [Article] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: NewsService
    private let favoritesStore: FavoritesStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(service: NewsService = LiveNewsService(), favoritesStore: FavoritesStore = UserDefaultsFavoritesStore()) {
        self.service = service
        self.favoritesStore = favoritesStore
        // Forward favorites changes to SwiftUI via objectWillChange
        favoritesStore.itemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Public
    func loadTopHeadlines(query: String? = nil) async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let items = try await service.topHeadlines(country: "us", query: query, page: 1, pageSize: 20)
            articles = items
        } catch is CancellationError {
            // Ignore user-initiated cancellations to avoid spurious alerts
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func refresh() async {
        await loadTopHeadlines()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Favorites
    var favoriteIDs: Set<String> { Set(favoritesStore.items.map { $0.id }) }
    var favoriteArticles: [Article] { favoritesStore.items.map { $0.asArticle } }
    func isFavorited(_ article: Article) -> Bool { favoriteIDs.contains(article.id) }
    func toggleFavorite(_ article: Article) { favoritesStore.toggle(article) }
}
