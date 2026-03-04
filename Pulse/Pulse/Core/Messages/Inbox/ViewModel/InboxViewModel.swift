//
//  InboxViewModel.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Foundation

@MainActor
final class InboxViewModel: ObservableObject {
    @Published var inboxThreads = [UserChatThreadIndex]()
    @Published var requestThreads = [UserChatThreadIndex]()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let threads = try await ChatService.fetchThreadIndices()
            inboxThreads = threads.filter { $0.state == .active }
            requestThreads = threads.filter { $0.state == .requested }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
