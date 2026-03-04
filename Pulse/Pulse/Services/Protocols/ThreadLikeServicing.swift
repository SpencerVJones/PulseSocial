//
//  ThreadLikeServicing.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import Foundation

protocol ThreadLikeServicing {
    func like(_ thread: Thread) async throws
    func unlike(_ thread: Thread) async throws
    func didLike(_ thread: Thread) async throws -> Bool
}

struct LiveThreadLikeService: ThreadLikeServicing {
    func like(_ thread: Thread) async throws {
        try await ThreadLikeService.likeThread(thread)
    }

    func unlike(_ thread: Thread) async throws {
        try await ThreadLikeService.unlikeThread(thread)
    }

    func didLike(_ thread: Thread) async throws -> Bool {
        try await ThreadLikeService.didLike(thread)
    }
}
