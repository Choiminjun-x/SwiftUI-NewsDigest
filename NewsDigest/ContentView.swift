//
//  ContentView.swift
//  NewsDigest
//
//  Created by 최민준(Minjun Choi) on 2/19/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Text("Apple releases new product")
                Text("SwiftUI gains popularity")
            }
            .navigationTitle("News")
            .searchable(text: $searchText)
        }
    }
}

#Preview {
    ContentView()
}
