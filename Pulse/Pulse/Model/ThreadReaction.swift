//
//  ThreadReaction.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import Foundation

enum ThreadReactionType: String, CaseIterable, Codable, Identifiable {
    case spark
    case mindblown
    case boost
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spark: return "Spark"
        case .mindblown: return "Mind blown"
        case .boost: return "Boost"
        case .deep: return "Deep"
        }
    }

    var emoji: String {
        switch self {
        case .spark: return "✨"
        case .mindblown: return "🤯"
        case .boost: return "🚀"
        case .deep: return "🧠"
        }
    }
}
