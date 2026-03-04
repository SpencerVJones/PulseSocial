//  CurrentUserProfileViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/8/25

import Foundation
import Combine
import PhotosUI
import SwiftUI

class CurrentUserProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var followerCount = 0
    @Published var followingCount = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscribers()
    }
    
    
    private func setupSubscribers() {
        UserService.shared.$currentUser.sink { [weak self] user in
            self?.currentUser = user
            Task { [weak self] in
                await self?.refreshFollowCounts()
            }
            print("DEBUG: User in view model from combine is \(String(describing: user))")
        }.store(in: &cancellables)
    }

    @MainActor
    func refreshFollowCounts() async {
        guard let uid = currentUser?.id else { return }

        do {
            followerCount = try await FollowService.fetchFollowerCount(for: uid)
            followingCount = try await FollowService.fetchFollowingCount(for: uid)
        } catch {
            print("DEBUG: Failed to refresh current user follow counts: \(error.localizedDescription)")
        }
    }
}
