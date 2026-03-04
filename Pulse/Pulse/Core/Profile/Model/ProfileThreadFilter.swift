//  ProfileThreadFilter.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import Foundation

enum ProfileThreadFilter: Int, CaseIterable, Identifiable {
    case threads
    case replies
    // could add likes, mentions
    
    var title: String {
        switch self {
        case .threads: return "Posts"
        case .replies: return "Replies"
        }
    }
    var id: Int { return self.rawValue }
}
