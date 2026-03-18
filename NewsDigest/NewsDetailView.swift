//
//  NewsDetailView.swift
//  NewsDigest
//
//  Created by 최민준(Minjun Choi) on 2/19/26.
//

import SwiftUI

struct NewsDetailView: View {
    let article: Article
    let onPopToRoot: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)

                Text("By \(article.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                Text(article.description)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NewsDetailView(
        article: Article(title: "Apple Releases New iOS Update", description: "Performance improvements and bug fixes.", author: "John Appleseed"),
        onPopToRoot: {}
    )
}

