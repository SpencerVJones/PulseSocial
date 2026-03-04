//
//  InviteMembersViewModel.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Foundation

@MainActor
final class InviteMembersViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var selectedUserIds = Set<String>()
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage = ""
    @Published var showError = false

    let threadId: String
    private let existingMemberIds: Set<String>

    init(threadId: String, existingMemberIds: Set<String>) {
        self.threadId = threadId
        self.existingMemberIds = existingMemberIds
    }

    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedUsers = try await UserService.fetchUsers()
            users = fetchedUsers.filter { !existingMemberIds.contains($0.id) }
        } catch {
            presentError(error)
        }
    }

    func toggleSelection(for userId: String) {
        if selectedUserIds.contains(userId) {
            selectedUserIds.remove(userId)
        } else {
            selectedUserIds.insert(userId)
        }
    }

    func sendInvites() async -> Bool {
        guard !selectedUserIds.isEmpty, !isSubmitting else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await ChatService.inviteUsers(
                toGroup: threadId,
                userIds: Array(selectedUserIds)
            )
            return true
        } catch {
            presentError(error)
            return false
        }
    }

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
