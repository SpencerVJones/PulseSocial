//
//  ThreadLikeService.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import FirebaseAuth
import FirebaseFirestore

struct ThreadLikeService {
    private static let db = Firestore.firestore()

    static func likeThread(_ thread: Thread) async throws {
        do {
            try await performLikeRemotely(
                threadId: thread.threadId ?? thread.operationId,
                threadOwnerUid: thread.ownerUid
            )
        } catch {
            await OfflineSyncService.shared.enqueueLike(for: thread, shouldLike: true)
        }
    }

    static func unlikeThread(_ thread: Thread) async throws {
        do {
            try await performUnlikeRemotely(threadId: thread.threadId ?? thread.operationId)
        } catch {
            await OfflineSyncService.shared.enqueueLike(for: thread, shouldLike: false)
        }
    }

    static func performLikeRemotely(
        threadId: String?,
        threadOwnerUid: String
    ) async throws {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let threadId
        else { return }

        let likeRef = db.collection("threads")
            .document(threadId)
            .collection("thread-likes")
            .document(currentUid)

        let existingSnapshot = try await likeRef.getDocument()
        guard !existingSnapshot.exists else { return }

        async let likeDocumentTask: Void = likeRef.setData([
            "uid": currentUid,
            "timestamp": Timestamp()
        ])

        async let likesCountTask: Void = db.collection("threads")
            .document(threadId)
            .updateData(["likes": FieldValue.increment(Int64(1))])

        _ = try await (likeDocumentTask, likesCountTask)
        try? await NotificationService.createNotification(toUid: threadOwnerUid, type: .like, threadId: threadId)
    }

    static func performUnlikeRemotely(threadId: String?) async throws {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let threadId
        else { return }

        let likeRef = db.collection("threads")
            .document(threadId)
            .collection("thread-likes")
            .document(currentUid)

        let existingSnapshot = try await likeRef.getDocument()
        guard existingSnapshot.exists else { return }

        async let unlikeDocumentTask: Void = likeRef.delete()

        async let likesCountTask: Void = db.collection("threads")
            .document(threadId)
            .updateData(["likes": FieldValue.increment(Int64(-1))])

        _ = try await (unlikeDocumentTask, likesCountTask)
    }

    static func didLike(_ thread: Thread) async throws -> Bool {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let threadId = thread.threadId
        else { return false }

        let snapshot = try await db.collection("threads")
            .document(threadId)
            .collection("thread-likes")
            .document(currentUid)
            .getDocument()

        return snapshot.exists
    }
}
