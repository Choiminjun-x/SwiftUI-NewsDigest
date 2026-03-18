//
//  NewsAPIModels.swift
//  NewsDigest
//
//  Created by Agent on 2026-02-19.
//

import Foundation

struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int?
    let articles: [NewsAPIArticle]
}

struct NewsAPIErrorResponse: Codable {
    let status: String
    let code: String?
    let message: String?
}

struct NewsAPIArticle: Codable {
    struct Source: Codable { let id: String?; let name: String? }

    let source: Source?
    let author: String?
    let title: String?
    let description: String?
    let url: URL?
    let urlToImage: URL?
    let publishedAt: Date?
    let content: String?
}

extension NewsAPIArticle {
    var domainModel: Article {
        Article(
            title: title ?? source?.name ?? "Untitled",
            description: description ?? content ?? "",
            author: author ?? "Unknown",
            url: url
        )
    }
}
