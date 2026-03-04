//
//  ProfileViewModel.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import FirebaseAuth
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var isFollowing = false
    @Published var isCloseFriend = false
    @Published var followerCount = 0
    @Published var followingCount = 0
    private let followService: FollowServicing

    var isCurrentUser: Bool {
        user.id == Auth.auth().currentUser?.uid
    }

    init(user: User, followService: FollowServicing = LiveFollowService()) {
        self.user = user
        self.followService = followService
    }

    func refresh() async {
        do {
            followerCount = try await followService.fetchFollowerCount(for: user.id)
            followingCount = try await followService.fetchFollowingCount(for: user.id)

            if !isCurrentUser {
                isFollowing = try await followService.isFollowing(uid: user.id)
                isCloseFriend = try await CloseFriendsService.isCloseFriend(uid: user.id)
            }
        } catch {
            print("DEBUG: Failed to refresh profile follow data: \(error.localizedDescription)")
        }
    }

    func toggleFollow() async {
        guard !isCurrentUser else { return }

        do {
            if isFollowing {
                try await followService.unfollow(uid: user.id)
                isFollowing = false
            } else {
                try await followService.follow(uid: user.id)
                isFollowing = true
            }

            await refresh()
        } catch {
            print("DEBUG: Failed to toggle follow: \(error.localizedDescription)")
        }
    }

    func toggleCloseFriend() async {
        guard !isCurrentUser else { return }

        do {
            if isCloseFriend {
                try await CloseFriendsService.remove(uid: user.id)
                isCloseFriend = false
            } else {
                try await CloseFriendsService.add(uid: user.id)
                isCloseFriend = true
            }
        } catch {
            print("DEBUG: Failed to toggle close friend: \(error.localizedDescription)")
        }
    }
}
