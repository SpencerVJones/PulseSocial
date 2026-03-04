//
//  ThreadNotification.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import Firebase
import FirebaseFirestore

enum ThreadNotificationType: String, Codable {
    case follow
    case like
    case comment
    case reaction
}

struct ThreadNotification: Identifiable, Codable {
    @DocumentID var notificationId: String?
    let type: ThreadNotificationType
    let fromUid: String
    let toUid: String
    let timestamp: Timestamp
    var threadId: String?
    var isRead: Bool

    var user: User?
    var thread: Thread?

    var id: String {
        notificationId ?? UUID().uuidString
    }
}
