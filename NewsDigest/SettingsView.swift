//
//  SettingsView.swift
//  NewsDigest
//
//  Created by 최민준(Minjun Choi) on 3/17/26.
//

import SwiftUI

struct SettingsView: View {

    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)

            Button("Close") {
                onClose()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
