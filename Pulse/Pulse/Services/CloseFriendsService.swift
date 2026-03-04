//
//  CloseFriendsService.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import FirebaseAuth
import FirebaseFirestore

struct CloseFriendsService {
    private static let db = Firestore.firestore()

    static func add(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid, currentUid != uid else { return }

        try await db.collection("close-friends")
            .document(currentUid)
            .collection("users")
            .document(uid)
            .setData(["timestamp": Timestamp()])
    }

    static func remove(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid, currentUid != uid else { return }

        try await db.collection("close-friends")
            .document(currentUid)
            .collection("users")
            .document(uid)
            .delete()
    }

    static func isCloseFriend(uid: String) async throws -> Bool {
        guard let currentUid = Auth.auth().currentUser?.uid, currentUid != uid else { return false }

        let snapshot = try await db.collection("close-friends")
            .document(currentUid)
            .collection("users")
            .document(uid)
            .getDocument()

        return snapshot.exists
    }

    static func fetchCloseFriendIDs() async throws -> Set<String> {
        guard let currentUid = Auth.auth().currentUser?.uid else { return [] }

        let snapshot = try await db.collection("close-friends")
            .document(currentUid)
            .collection("users")
            .getDocuments()

        return Set(snapshot.documents.map(\.documentID))
    }
}
