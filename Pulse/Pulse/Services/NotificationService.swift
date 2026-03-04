//
//  NotificationService.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let db = Firestore.firestore()

    private init() {}

    func requestAuthorizationIfNeeded() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("DEBUG: Failed to request push permission: \(error.localizedDescription)")
        }
    }

    func updateFCMToken(_ token: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            try await db.collection("users")
                .document(uid)
                .setData(["fcmToken": token], merge: true)
        } catch {
            print("DEBUG: Failed to save FCM token: \(error.localizedDescription)")
        }
    }

    func syncCurrentFCMTokenToLoggedInUser() async {
        guard let token = Messaging.messaging().fcmToken else { return }
        await updateFCMToken(token)
    }

    static func createNotification(
        toUid: String,
        type: ThreadNotificationType,
        threadId: String? = nil
    ) async throws {
        guard let fromUid = Auth.auth().currentUser?.uid, fromUid != toUid else { return }

        let notification = ThreadNotification(
            type: type,
            fromUid: fromUid,
            toUid: toUid,
            timestamp: Timestamp(),
            threadId: threadId,
            isRead: false
        )

        guard let notificationData = try? Firestore.Encoder().encode(notification) else { return }

        try await Firestore.firestore()
            .collection("notifications")
            .document(toUid)
            .collection("user-notifications")
            .addDocument(data: notificationData)
    }

    static func fetchNotifications() async throws -> [ThreadNotification] {
        guard let currentUid = Auth.auth().currentUser?.uid else { return [] }

        let snapshot = try await Firestore.firestore()
            .collection("notifications")
            .document(currentUid)
            .collection("user-notifications")
            .order(by: "timestamp", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ThreadNotification.self) }
    }

    static func markAsRead(_ notification: ThreadNotification) async throws {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let notificationId = notification.notificationId
        else { return }

        try await Firestore.firestore()
            .collection("notifications")
            .document(currentUid)
            .collection("user-notifications")
            .document(notificationId)
            .updateData(["isRead": true])
    }
}
