//
//  UserFollowViewModel.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import FirebaseAuth
import Foundation

@MainActor
final class UserFollowViewModel: ObservableObject {
    @Published var isFollowing = false
    @Published var isLoading = false

    let user: User
    private let followService: FollowServicing

    var isCurrentUser: Bool {
        user.id == Auth.auth().currentUser?.uid
    }

    init(user: User, followService: FollowServicing = LiveFollowService()) {
        self.user = user
        self.followService = followService
        self.isFollowing = user.isFollowed ?? false
    }

    func refreshState() async {
        guard !isCurrentUser else { return }

        do {
            isFollowing = try await followService.isFollowing(uid: user.id)
        } catch {
            print("DEBUG: Failed to refresh follow state: \(error.localizedDescription)")
        }
    }

    func toggleFollow() async {
        guard !isCurrentUser, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if isFollowing {
                try await followService.unfollow(uid: user.id)
                isFollowing = false
            } else {
                try await followService.follow(uid: user.id)
                isFollowing = true
            }
        } catch {
            print("DEBUG: Failed to toggle follow from user cell: \(error.localizedDescription)")
        }
    }
}
