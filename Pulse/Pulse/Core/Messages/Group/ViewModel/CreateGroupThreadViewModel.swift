//
//  CreateGroupThreadViewModel.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Foundation

enum CreateGroupThreadError: LocalizedError {
    case missingTitle
    case missingMembers

    var errorDescription: String? {
        switch self {
        case .missingTitle:
            return "Add a group name."
        case .missingMembers:
            return "Pick at least one person to add."
        }
    }
}

@MainActor
final class CreateGroupThreadViewModel: ObservableObject {
    @Published var title = ""
    @Published var users = [User]()
    @Published var selectedUserIds = Set<String>()
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage = ""
    @Published var showError = false

    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            users = try await UserService.fetchUsers()
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

    func createGroup() async -> ChatThread? {
        guard !isSubmitting else { return nil }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            presentError(CreateGroupThreadError.missingTitle)
            return nil
        }

        guard !selectedUserIds.isEmpty else {
            presentError(CreateGroupThreadError.missingMembers)
            return nil
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            return try await ChatService.createGroupThread(
                title: trimmedTitle,
                memberIds: Array(selectedUserIds)
            )
        } catch {
            presentError(error)
            return nil
        }
    }

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
