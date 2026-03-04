//
//  VoiceClipPlayerView.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import AVFoundation
import SwiftUI

struct VoiceClipPlayerView: View {
    let audioUrl: String
    let duration: TimeInterval?

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Voice clip")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let duration {
                    Text(format(duration: duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "waveform")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
        )
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }

    private func togglePlayback() {
        guard let url = URL(string: audioUrl) else { return }

        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        if player == nil {
            player = AVPlayer(url: url)
        }

        player?.play()
        isPlaying = true
    }

    private func format(duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
