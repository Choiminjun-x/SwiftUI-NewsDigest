//
//  NewsListView.swift
//  NewsDigest
//
//  Created by 최민준(Minjun Choi) on 2/19/26.
//

import SwiftUI

enum Route: Hashable {
    case detail(Article)
    case settings
}

struct NewsListView: View {
    
    @StateObject private var viewModel = NewsViewModel()
    @State private var path: [Route] = []
    @State private var searchText: String = ""
    @State private var showError: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil
    
    var body: some View {
        NavigationStack(path: $path) {
            content
            .navigationTitle("News")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        path.append(.settings)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            // 🔥 Route 기반 destination 매핑
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            .searchable(text: $searchText)
            .onChange(of: searchText) { newValue in
                // Debounce search to avoid rapid reloads during typing
                searchTask?.cancel()
                searchTask = Task { [newValue] in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    if Task.isCancelled { return }
                    await viewModel.loadTopHeadlines(query: newValue.isEmpty ? nil : newValue)
                }
            }
            .task { await viewModel.loadTopHeadlines() }
            .onChange(of: viewModel.errorMessage) { newValue in
                showError = (newValue != nil)
            }
            .alert("Error", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { viewModel.clearError() }
                Button("Retry") { Task { await viewModel.refresh() } }
            }, message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            })
            .tint(.blue)
        }
    }

    
    // MARK: - Subviews
    @ViewBuilder
    private var content: some View {
        ZStack {
            List {
                // Favorites section (if exists)
                if !viewModel.favoriteArticles.isEmpty {
                    Section("Favorites") {
                        ForEach(viewModel.favoriteArticles) { article in
                            NavigationLink(value: Route.detail(article)) {
                                NewsRowView(article: article, isBookmarked: true)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { viewModel.toggleFavorite(article) } label: {
                                    Label("Unfavorite", systemImage: "bookmark.slash")
                                }
                            }
                        }
                    }
                }

                // All articles
                Section("All News") {
                    let favoriteIDs = viewModel.favoriteIDs
                    ForEach(viewModel.articles.filter { !favoriteIDs.contains($0.id) }) { article in
                        NavigationLink(value: Route.detail(article)) {
                            NewsRowView(article: article, isBookmarked: viewModel.isFavorited(article))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if viewModel.isFavorited(article) {
                                Button(role: .destructive) { viewModel.toggleFavorite(article) } label: {
                                    Label("Unfavorite", systemImage: "bookmark.slash")
                                }
                            } else {
                                Button { viewModel.toggleFavorite(article) } label: {
                                    Label("Favorite", systemImage: "bookmark")
                                }.tint(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.refresh() }

            // Loading overlay (only when initially loading with empty list)
            if viewModel.isLoading && viewModel.articles.isEmpty {
                ProgressView("Loading...")
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .detail(let article):
            NewsDetailView(article: article) {
                path.removeAll()
            }
        case .settings:
            SettingsView {
                path.removeLast()
            }
        }
    }
}


#Preview {
    NewsListView()
}
