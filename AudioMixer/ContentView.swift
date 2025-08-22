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
            spotifyController.startPlaybackMonitor(every: 1)
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
                
                VStack(alignment: .leading, spacing: 2) {
                    // Title marquee
                    MarqueeText(
                        text: track?.name ?? "No track playing",
                        font: .system(size: 20, weight: .semibold),
                        speed: 50,
                        delay: 0.8
                    )
                    // Artist marquee (smaller)
                    MarqueeText(
                        text: track?.artists.first?.name ?? "",
                        font: .system(size: 16),
                        speed: 50,
                        delay: 0.8
                    )
                    .foregroundColor(.secondary)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                if duration > 0 {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Text(formatMs(progress))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                                .frame(width: 36, alignment: .leading)

                            ScrubbableProgressBar(
                                progressMs: progress,
                                durationMs: duration,
                                trackColor: Color.black.opacity(0.35),
                                fillColor: .white,
                                height: 6,
                                onScrub: { newMs in
                                    spotifyController.currentProgressMs = newMs
                                },
                                onScrubEnd: { newMs in
                                    spotifyController.skipToTimestamp(positionMs: newMs)
                                }
                            )

                            Text(formatMs(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }

                HStack(spacing: 16) {
                    Spacer()

                    Button {
                        spotifyController.skipBack { ok in
                        if ok {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                spotifyController.getSongStatus()
                            }
                        }}
                        print("Skip back tapped")
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!spotifyController.isTokenValid)

                    Button {
                        spotifyController.togglePlayPause { ok in
                            if ok {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    spotifyController.getSongStatus()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .disabled(!spotifyController.isTokenValid)

                    // Skip Forward
                    Button {
                        spotifyController.skipSong { ok in
                        if ok {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                spotifyController.getSongStatus()
                            }
                        }}
                        print("Skip forward tapped")
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!spotifyController.isTokenValid)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 350)
        .padding()
    }
}

#Preview {
    ItemRow()
        .environmentObject(SpotifyController())
}
