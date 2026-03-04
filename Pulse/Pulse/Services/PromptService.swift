//
//  PromptService.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import Foundation

enum PromptService {
    private static let prompts: [PostingPrompt] = [
        PostingPrompt(id: "ship-log", title: "Ship log", description: "What did you ship this week?"),
        PostingPrompt(id: "hot-take", title: "Hot take", description: "Share one bold opinion in your niche."),
        PostingPrompt(id: "build-public", title: "Build in public update", description: "What are you building today?"),
        PostingPrompt(id: "learned", title: "Today I learned", description: "One insight worth passing on."),
        PostingPrompt(id: "micro-win", title: "Micro win", description: "Small win, big momentum.")
    ]

    static func dailyPrompt(for date: Date = .now) -> PostingPrompt {
        guard !prompts.isEmpty else {
            return PostingPrompt(id: "default", title: "Daily prompt", description: "Share what you are working on.")
        }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = day % prompts.count
        return prompts[index]
    }
}
