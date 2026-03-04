//
//  FeedAlgorithm.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import Foundation

enum FeedAlgorithm: String, CaseIterable, Identifiable {
    case ranked
    case newest
    case followingOnly
    case closeFriends

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ranked: return "Ranked"
        case .newest: return "Newest"
        case .followingOnly: return "Following"
        case .closeFriends: return "Close Friends"
        }
    }
}
