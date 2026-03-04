//  UserContentListViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/13/25

import Foundation

class UserContentListViewModel: ObservableObject {
    @Published var threads = [Thread]()
    @Published var replies = [ThreadComment]()
    let user: User
    
    init(user: User) {
        self.user = user
        Task { await refresh() }
    }
    
    @MainActor
    func refresh() async {
        do {
            try await fetchUserThreads()
            try await fetchUserReplies()
        } catch {
            print("DEBUG: Failed to refresh profile posts: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func fetchUserThreads() async throws {
        self.threads = try await ThreadService.fetchUserTreads(uid: user.id)
        
        for i in 0..<threads.count {
            threads[i].user = self.user
        }
        
        self.threads = threads
    }

    @MainActor
    private func fetchUserReplies() async throws {
        self.replies = try await CommentService.fetchComments(forUserId: user.id)

        for index in replies.indices {
            replies[index].user = self.user
        }
    }
}
