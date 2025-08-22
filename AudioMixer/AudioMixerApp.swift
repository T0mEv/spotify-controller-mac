//
//  AudioMixerApp.swift
//  AudioMixer
//
//  Created by Thomas Evans on 20/07/2025.
//

import SwiftUI

@main
struct AudioMixerApp: App {
    @StateObject private var spotifyController = SpotifyController()

    var body: some Scene {
        MenuBarExtra("AudioMixer", systemImage: "music.note") {
            ItemRow()
                .environmentObject(spotifyController)
        }
        .menuBarExtraStyle(.window)

        WindowGroup {
            EmptyView()
                .onOpenURL { url in
                    handleSpotifyCallback(url: url)
                }
        }
        .handlesExternalEvents(matching: ["audiomixer"])
    }

    private func handleSpotifyCallback(url: URL) {
        print("App was opened by URL: \(url)")
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("Error: Could not find authorization code in URL.")
            return
        }
        if !code.isEmpty {
            spotifyController.exchangeCodeForToken(code: code)
        }
    }
}