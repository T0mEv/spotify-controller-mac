//
//  ContentView.swift
//  AudioMixer
//
//  Created by Thomas Evans on 20/07/2025.
//

import SwiftUI

private func formatMs(_ ms: Int) -> String {
    let secs = ms / 1000
    return String(format: "%d:%02d", secs / 60, secs % 60)
}

struct ItemRow: View {
    @EnvironmentObject var spotifyController: SpotifyController
    
    var body: some View {
        Group {
            if !(spotifyController.accessToken != nil && spotifyController.isTokenValid) {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Button("Connect to Spotify") {
                        spotifyController.authorize()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(width: 280, alignment: .center)
                .padding()
            } else {
                contentView
            }
        }
        .onAppear {
            spotifyController.startPlaybackMonitor(every: 1) // faster updates
        }
        .onDisappear {
            spotifyController.stopPlaybackMonitor()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        let track = spotifyController.nowPlaying
        let isPlaying = spotifyController.isPlayingNow
        let progress = spotifyController.currentProgressMs ?? 0
        let duration = track?.durationMs ?? 0
        let artworkURL = track?.album.images.first?.url
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: artworkURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .cornerRadius(6)
                    case .empty:
                        ZStack {
                            Rectangle().fill(Color.secondary.opacity(0.15))
                            Image(systemName: "music.note")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 64, height: 64)
                        .cornerRadius(6)
                    case .failure:
                        ZStack {
                            Rectangle().fill(Color.secondary.opacity(0.15))
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 64, height: 64)
                        .cornerRadius(6)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track?.name ?? "No track playing")
                        .font(.headline)
                        .lineLimit(2)
                    Text(track?.artists.first?.name ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            if duration > 0 {
                VStack(spacing: 6) {
                    ProgressView(value: Double(progress), total: Double(duration))
                        .progressViewStyle(.linear)
                    HStack {
                        Text(formatMs(progress))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatMs(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Button(isPlaying ? "Pause" : "Play") {
                    spotifyController.togglePlayPause { ok in
                        if ok {
                            // quick sync
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                spotifyController.getSongStatus()
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!spotifyController.isTokenValid)
                
                Spacer()
            }
        }
        .frame(width: 280)
        .padding()
    }
}

#Preview {
    ItemRow()
        .environmentObject(SpotifyController())
}