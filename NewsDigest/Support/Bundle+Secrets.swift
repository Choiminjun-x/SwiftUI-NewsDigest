//
//  Bundle+Secrets.swift
//  NewsDigest
//
//  Created by Agent on 2026-02-19.
//

import Foundation

extension Bundle {
    var newsAPIKey: String? {
        // Configure your API key via Info.plist with key: NEWS_API_KEY
        object(forInfoDictionaryKey: "NEWS_API_KEY") as? String
    }
}

