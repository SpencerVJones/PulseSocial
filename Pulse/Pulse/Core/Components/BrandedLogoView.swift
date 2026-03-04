//  BrandedLogoView.swift
//  Pulse
//
//  Created by Codex on 2/27/26.
//

import AVKit
import SwiftUI
import UIKit

struct BrandedLogoView: View {
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    private var assetName: String {
        colorScheme == .dark ? "Logo_Dark_Img" : "Logo_Light_Img"
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

struct BrandedLoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var player: AVPlayer?

    private var videoAssetName: String {
        colorScheme == .dark ? "Logo_Dark_Vid" : "Logo_Light_Vid"
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if let player {
                    VideoPlayer(player: player)
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .allowsHitTesting(false)
                } else {
                    BrandedLogoView(size: 180)
                }

                Text("Pulse")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 24)
        }
        .task(id: videoAssetName) {
            configurePlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func configurePlayer() {
        guard let dataAsset = NSDataAsset(name: videoAssetName) else {
            player = nil
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(videoAssetName).mp4")

        do {
            try dataAsset.data.write(to: url, options: .atomic)
            let player = AVPlayer(url: url)
            player.isMuted = true
            player.actionAtItemEnd = .none
            self.player = player
            player.play()
        } catch {
            player = nil
        }
    }
}

