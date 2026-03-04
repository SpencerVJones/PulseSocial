//
//  ThreadReactionService.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import FirebaseAuth
import FirebaseFirestore

struct ThreadReactionService {
    private static let db = Firestore.firestore()

    static func fetchCurrentUserReaction(for thread: Thread) async throws -> ThreadReactionType? {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let threadId = thread.threadId
        else { return nil }

        let snapshot = try await db.collection("threads")
            .document(threadId)
            .collection("thread-reactions")
            .document(currentUid)
            .getDocument()

        guard
            let rawValue = snapshot.data()?["type"] as? String,
            let reaction = ThreadReactionType(rawValue: rawValue)
        else { return nil }

        return reaction
    }

    static func setReaction(_ reaction: ThreadReactionType, on thread: Thread) async throws {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let threadId = thread.threadId
        else { return }

        let threadRef = db.collection("threads").document(threadId)
        let reactionRef = threadRef.collection("thread-reactions").document(currentUid)
        let existingSnapshot = try await reactionRef.getDocument()
        let existingRawValue = existingSnapshot.data()?["type"] as? String

        let batch = db.batch()

        if let existingRawValue {
            batch.updateData(
                ["reactionCounts.\(existingRawValue)": FieldValue.increment(Int64(-1))],
                forDocument: threadRef
            )
        }

        if existingRawValue == reaction.rawValue {
            batch.deleteDocument(reactionRef)
        } else {
            batch.setData(
                [
                    "uid": currentUid,
                    "type": reaction.rawValue,
                    "timestamp": Timestamp()
                ],
                forDocument: reactionRef
            )

            batch.updateData(
                ["reactionCounts.\(reaction.rawValue)": FieldValue.increment(Int64(1))],
                forDocument: threadRef
            )
        }

        try await batch.commit()

        if existingRawValue != reaction.rawValue {
            try await NotificationService.createNotification(toUid: thread.ownerUid, type: .reaction, threadId: threadId)
        }
    }
}
