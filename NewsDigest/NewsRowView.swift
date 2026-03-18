//
//  NewsRowView.swift
//  NewsDigest
//
//  Created by Agent on 2026-03-17.
//

import SwiftUI

struct NewsRowView: View {
    let article: Article
    var isBookmarked: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Text(article.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(article.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title). \(article.description). Author: \(article.author)")
    }
}

#Preview {
    NewsRowView(article: Article(title: "Title", description: "Desc", author: "Auth", url: nil), isBookmarked: true)
        .padding()
}
