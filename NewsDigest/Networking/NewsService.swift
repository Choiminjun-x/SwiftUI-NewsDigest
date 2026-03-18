//
//  NewsService.swift
//  NewsDigest
//
//  Created by Agent on 2026-02-19.
//

import Foundation

// MARK: - Protocol
protocol NewsService {
    func topHeadlines(country: String?, query: String?, page: Int, pageSize: Int) async throws -> [Article]
}

// MARK: - Errors
enum NewsServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case badStatus(Int)
    case decoding
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API key is missing. Add NEWS_API_KEY to Info.plist (Do not commit real secrets)."
        case .invalidURL: return "Failed to construct request URL."
        case .badStatus(let code): return "Server responded with status code: \(code)."
        case .decoding: return "Failed to decode server response."
        case .server(let message): return message
        }
    }
}

// MARK: - Live Implementation
struct LiveNewsService: NewsService {
    private let session: URLSession
    private let baseURL = URL(string: "https://newsapi.org/v2")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func topHeadlines(country: String?, query: String?, page: Int, pageSize: Int) async throws -> [Article] {
        guard let apiKey = Bundle.main.newsAPIKey, !apiKey.isEmpty else {
            throw NewsServiceError.missingAPIKey
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("top-headlines"), resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = []
        if let country, !country.isEmpty { items.append(URLQueryItem(name: "country", value: country)) }
        if let query, !query.isEmpty { items.append(URLQueryItem(name: "q", value: query)) }
        items.append(URLQueryItem(name: "page", value: String(page)))
        items.append(URLQueryItem(name: "pageSize", value: String(pageSize)))
        components?.queryItems = items

        guard let url = components?.url else { throw NewsServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key") // per NewsAPI docs

        #if DEBUG
        print("[NewsService] Request: GET \(request.url?.absoluteString ?? "-")")
        #endif

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            #if DEBUG
            let snippet = String(data: data.prefix(512), encoding: .utf8) ?? "<non-utf8>"
            print("[NewsService] Non-2xx status=\(status) bodySnippet=\(snippet)")
            #endif
            if let apiError = try? JSONDecoder().decode(NewsAPIErrorResponse.self, from: data), let msg = apiError.message {
                throw NewsServiceError.server("\(msg) [code: \(apiError.code ?? "-")]")
            }
            throw NewsServiceError.badStatus(status)
        }

        do {
            let decoded = try JSONDecoder.news.decode(NewsAPIResponse.self, from: data)
            return decoded.articles.map { $0.domainModel }
        } catch {
            #if DEBUG
            if let decodingError = error as? DecodingError {
                print("[NewsService] DecodingError: \(decodingError)")
            } else {
                print("[NewsService] Decode failed: \(error.localizedDescription)")
            }
            let snippet = String(data: data.prefix(512), encoding: .utf8) ?? "<non-utf8>"
            print("[NewsService] Response snippet: \(snippet)")
            #endif
            throw NewsServiceError.decoding
        }
    }
}

// MARK: - JSON Decoder
private extension JSONDecoder {
    static let news: JSONDecoder = {
        let d = JSONDecoder()
        // Robust ISO8601 decoding (with and without fractional seconds)
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            // with fractional seconds
            let isoFS = ISO8601DateFormatter()
            isoFS.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFS.date(from: string) { return date }

            // without fractional seconds
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: string) { return date }

            // Fallback: try RFC3339 formatter
            let rfc = DateFormatter()
            rfc.locale = Locale(identifier: "en_US_POSIX")
            rfc.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = rfc.date(from: string) { return date }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return d
    }()
}
