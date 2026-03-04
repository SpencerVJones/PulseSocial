//
//  ActivityViewModel.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var notifications = [ThreadNotification]()
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestMode")

    func fetchNotifications() async {
        if isUITesting {
            notifications = DeveloperPreview.shared.activityNotifications
            return
        }

        do {
            var fetched = try await NotificationService.fetchNotifications()

            for index in fetched.indices {
                fetched[index].user = try await UserService.fetchUser(withUid: fetched[index].fromUid)

                if let threadId = fetched[index].threadId {
                    fetched[index].thread = try await ThreadService.fetchThread(withId: threadId)
                }
            }

            notifications = fetched
        } catch {
            print("DEBUG: Failed to fetch notifications: \(error.localizedDescription)")
        }
    }
}
