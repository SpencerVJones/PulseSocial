//  ExploreViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/8/25

import Foundation
import Firebase

class ExploreViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var publicBoards = [Board]()
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestMode")
    
    init() {
        Task { await refresh() }
    }

    @MainActor
    func refresh() async {
        if isUITesting {
            users = DeveloperPreview.shared.exploreUsers
            publicBoards = [
                Board(
                    ownerUid: DeveloperPreview.shared.user.id,
                    name: "Launch Notes",
                    isPublic: true,
                    timestamp: Timestamp(date: Date()),
                    itemCount: 3
                )
            ]
            return
        }

        do {
            async let usersTask = UserService.fetchUsers()
            async let boardsTask = BoardService.fetchPublicBoards()

            users = try await usersTask
            publicBoards = try await boardsTask
        } catch {
            print("DEBUG: Failed to refresh explore data: \(error.localizedDescription)")
        }
    }
}
