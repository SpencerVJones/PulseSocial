//
//  FollowServicing.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import Foundation

protocol FollowServicing {
    func follow(uid: String) async throws
    func unfollow(uid: String) async throws
    func isFollowing(uid: String) async throws -> Bool
    func fetchFollowerCount(for uid: String) async throws -> Int
    func fetchFollowingCount(for uid: String) async throws -> Int
}

struct LiveFollowService: FollowServicing {
    func follow(uid: String) async throws {
        try await FollowService.follow(uid: uid)
    }

    func unfollow(uid: String) async throws {
        try await FollowService.unfollow(uid: uid)
    }

    func isFollowing(uid: String) async throws -> Bool {
        try await FollowService.isFollowing(uid: uid)
    }

    func fetchFollowerCount(for uid: String) async throws -> Int {
        try await FollowService.fetchFollowerCount(for: uid)
    }

    func fetchFollowingCount(for uid: String) async throws -> Int {
        try await FollowService.fetchFollowingCount(for: uid)
    }
}
