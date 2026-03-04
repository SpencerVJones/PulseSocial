//
//  GroupMembersViewModel.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Foundation

@MainActor
final class GroupMembersViewModel: ObservableObject {
    @Published var thread: ChatThread?
    @Published var currentMembership: ChatThreadMember?
    @Published var members = [ChatMemberDetail]()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false

    let threadId: String

    init(threadId: String) {
        self.threadId = threadId
    }

    var isAdmin: Bool {
        currentMembership?.role == .admin && currentMembership?.state == .active
    }

    var memberIds: Set<String> {
        Set(members.map { $0.user.id })
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let threadTask = ChatService.fetchThread(threadId: threadId)
            async let membershipTask = ChatService.fetchMembership(threadId: threadId)
            async let membersTask = ChatService.fetchMemberDetails(threadId: threadId)

            thread = try await threadTask
            currentMembership = try await membershipTask
            members = try await membersTask
        } catch {
            presentError(error)
        }
    }

    func promote(_ member: ChatMemberDetail) async {
        await updateRole(for: member, role: .admin)
    }

    func demote(_ member: ChatMemberDetail) async {
        await updateRole(for: member, role: .member)
    }

    func remove(_ member: ChatMemberDetail) async {
        do {
            try await ChatService.removeMember(fromGroup: threadId, memberId: member.user.id)
            await refresh()
        } catch {
            presentError(error)
        }
    }

    private func updateRole(for member: ChatMemberDetail, role: ChatMemberRole) async {
        do {
            try await ChatService.updateMemberRole(
                threadId: threadId,
                memberId: member.user.id,
                role: role
            )
            await refresh()
        } catch {
            presentError(error)
        }
    }

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
