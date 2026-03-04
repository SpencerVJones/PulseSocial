//
//  CircleService.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import Foundation

enum CircleService {
    static let defaultCircle = Circle(
        id: "general",
        name: "General",
        symbol: "bubble.left.and.bubble.right",
        tagline: "Open conversations"
    )

    static let circles: [Circle] = [
        defaultCircle,
        Circle(id: "build-in-public", name: "Build In Public", symbol: "hammer", tagline: "Ship notes + progress logs"),
        Circle(id: "hot-takes", name: "Hot Takes", symbol: "flame", tagline: "Quick opinions and debates"),
        Circle(id: "career-lab", name: "Career Lab", symbol: "briefcase", tagline: "Jobs, resumes, interviews"),
        Circle(id: "creator-corner", name: "Creator Corner", symbol: "sparkles", tagline: "Content + growth experiments"),
        Circle(id: "local-loop", name: "Local Loop", symbol: "location", tagline: "City and campus updates")
    ]

    static func fetchCircles() async -> [Circle] {
        circles
    }
}
