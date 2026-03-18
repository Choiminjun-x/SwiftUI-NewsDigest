//
//  FavoritesStore.swift
//  NewsDigest
//
//  Created by Agent on 2026-03-17.
//

import Foundation
import Combine

// MARK: - Model for persistence
struct FavoriteItem: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let description: String
    let author: String
    let urlString: String?

    var url: URL? { urlString.flatMap(URL.init(string:)) }
    var asArticle: Article {
        Article(id: id, title: title, description: description, author: author, url: url)
    }
}

// MARK: - Store Protocol
protocol FavoritesStore: AnyObject {
    var items: [FavoriteItem] { get }
    func isFavorited(_ id: String) -> Bool
    func toggle(_ article: Article)
    var itemsPublisher: AnyPublisher<[FavoriteItem], Never> { get }
}

// MARK: - UserDefaults Implementation
final class UserDefaultsFavoritesStore: FavoritesStore, ObservableObject {
    private let key = "com.dev.newsdigest.favorites.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaults: UserDefaults

    @Published private(set) var items: [FavoriteItem] = [] { didSet { persist() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.items = load()
    }

    func isFavorited(_ id: String) -> Bool { items.contains { $0.id == id } }

    func toggle(_ article: Article) {
        if let idx = items.firstIndex(where: { $0.id == article.id }) {
            items.remove(at: idx)
        } else {
            let item = FavoriteItem(
                id: article.id,
                title: article.title,
                description: article.description,
                author: article.author,
                urlString: article.url?.absoluteString
            )
            items.insert(item, at: 0)
        }
    }

    var itemsPublisher: AnyPublisher<[FavoriteItem], Never> { $items.eraseToAnyPublisher() }

    // MARK: - Persistence
    private func load() -> [FavoriteItem] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? decoder.decode([FavoriteItem].self, from: data)) ?? []
    }

    private func persist() {
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: key)
        }
    }
}
