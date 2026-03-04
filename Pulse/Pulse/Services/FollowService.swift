//
//  FollowService.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import FirebaseAuth
import FirebaseFirestore

struct FollowService {
    private static let db = Firestore.firestore()

    static func follow(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid, currentUid != uid else { return }

        async let followingTask: Void = db.collection("following")
            .document(currentUid)
            .collection("user-following")
            .document(uid)
            .setData(["timestamp": Timestamp()])

        async let followersTask: Void = db.collection("followers")
            .document(uid)
            .collection("user-followers")
            .document(currentUid)
            .setData(["timestamp": Timestamp()])

        _ = try await (followingTask, followersTask)
        try await NotificationService.createNotification(toUid: uid, type: .follow)
        try await UserService.shared.refreshCurrentUserStats()
    }

    static func unfollow(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid, currentUid != uid else { return }

        async let followingTask: Void = db.collection("following")
            .document(currentUid)
            .collection("user-following")
            .document(uid)
            .delete()

        async let followersTask: Void = db.collection("followers")
            .document(uid)
            .collection("user-followers")
            .document(currentUid)
            .delete()

        _ = try await (followingTask, followersTask)
        try await UserService.shared.refreshCurrentUserStats()
    }

    static func isFollowing(uid: String) async throws -> Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        let snapshot = try await db.collection("following")
            .document(currentUid)
            .collection("user-following")
            .document(uid)
            .getDocument()

        return snapshot.exists
    }

    static func isUser(_ followerId: String, following followedId: String) async throws -> Bool {
        let snapshot = try await db.collection("following")
            .document(followerId)
            .collection("user-following")
            .document(followedId)
            .getDocument()

        return snapshot.exists
    }

    static func fetchFollowerCount(for uid: String) async throws -> Int {
        let snapshot = try await db.collection("followers")
            .document(uid)
            .collection("user-followers")
            .getDocuments()

        return snapshot.documents.count
    }

    static func fetchFollowingCount(for uid: String) async throws -> Int {
        let snapshot = try await db.collection("following")
            .document(uid)
            .collection("user-following")
            .getDocuments()

        return snapshot.documents.count
    }

    static func fetchFollowingIDs() async throws -> Set<String> {
        guard let currentUid = Auth.auth().currentUser?.uid else { return [] }

        let snapshot = try await db.collection("following")
            .document(currentUid)
            .collection("user-following")
            .getDocuments()

        return Set(snapshot.documents.map(\.documentID))
    }
}
