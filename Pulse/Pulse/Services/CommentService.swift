//
//  CommentService.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import FirebaseAuth
import FirebaseFirestore

struct CommentService {
    private static let db = Firestore.firestore()

    static func addComment(
        to thread: Thread,
        text: String,
        voiceClipFileURL: URL? = nil,
        voiceClipDuration: TimeInterval? = nil
    ) async throws {
        guard Auth.auth().currentUser?.uid != nil else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var uploadedVoiceClipUrl: String?

        if let voiceClipFileURL {
            uploadedVoiceClipUrl = try await ImageUploader.uploadCommentVoiceClip(from: voiceClipFileURL)
        }

        guard !trimmedText.isEmpty || uploadedVoiceClipUrl != nil else { return }

        let operationId = UUID().uuidString

        do {
            try await addCommentRemotely(
                threadId: thread.threadId ?? thread.operationId,
                threadOwnerUid: thread.ownerUid,
                text: trimmedText,
                voiceClipUrl: uploadedVoiceClipUrl,
                voiceClipDuration: voiceClipDuration,
                ownerUsername: UserService.shared.currentUser?.username,
                ownerProfileImageUrl: UserService.shared.currentUser?.profileImageUrl,
                operationId: operationId,
                timestamp: Timestamp()
            )
        } catch {
            await OfflineSyncService.shared.enqueueComment(
                for: thread,
                text: trimmedText,
                voiceClipUrl: uploadedVoiceClipUrl,
                voiceClipDuration: voiceClipDuration,
                operationId: operationId
            )
        }
    }

    static func addCommentRemotely(
        threadId: String?,
        threadOwnerUid: String,
        text: String,
        voiceClipUrl: String?,
        voiceClipDuration: TimeInterval?,
        ownerUsername: String?,
        ownerProfileImageUrl: String?,
        operationId: String,
        timestamp: Timestamp
    ) async throws {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let threadId
        else { return }

        let commentRef = db.collection("threads")
            .document(threadId)
            .collection("comments")
            .document(operationId)

        let existingSnapshot = try await commentRef.getDocument()
        guard !existingSnapshot.exists else { return }

        let comment = ThreadComment(
            threadId: threadId,
            ownerUid: currentUid,
            commentText: text,
            timestamp: timestamp,
            ownerUsername: ownerUsername,
            ownerProfileImageUrl: ownerProfileImageUrl,
            voiceClipUrl: voiceClipUrl,
            voiceClipDuration: voiceClipDuration
        )

        guard let commentData = try? Firestore.Encoder().encode(comment) else { return }

        async let commentWriteTask: Void = commentRef.setData(commentData)

        async let updateThreadCommentCountTask: Void = db.collection("threads")
            .document(threadId)
            .updateData(["commentCount": FieldValue.increment(Int64(1))])

        _ = try await (commentWriteTask, updateThreadCommentCountTask)
        try? await NotificationService.createNotification(toUid: threadOwnerUid, type: .comment, threadId: threadId)
    }

    static func fetchComments(for thread: Thread) async throws -> [ThreadComment] {
        guard let threadId = thread.threadId ?? thread.operationId else { return [] }
        let snapshot = try await db.collection("threads")
            .document(threadId)
            .collection("comments")
            .order(by: "timestamp", descending: true)
            .getDocuments()

        var comments = snapshot.documents.compactMap { try? $0.data(as: ThreadComment.self) }

        for index in comments.indices {
            let ownerUid = comments[index].ownerUid
            comments[index].user = try await UserService.fetchUser(withUid: ownerUid)
        }

        let pendingComments = await OfflineSyncService.shared.pendingComments(forThreadId: threadId)
        let existingIds = Set(comments.compactMap(\.commentId))
        comments.append(contentsOf: pendingComments.filter { pendingComment in
            guard let commentId = pendingComment.commentId else { return true }
            return !existingIds.contains(commentId)
        })
        comments.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }

        return comments
    }

    static func fetchComments(forUserId uid: String) async throws -> [ThreadComment] {
        let snapshot = try await db.collectionGroup("comments")
            .whereField("ownerUid", isEqualTo: uid)
            .getDocuments()

        var comments = snapshot.documents
            .compactMap { try? $0.data(as: ThreadComment.self) }

        let pendingComments = await OfflineSyncService.shared.pendingComments(forOwnerUid: uid)
        let existingIds = Set(comments.compactMap(\.commentId))
        comments.append(contentsOf: pendingComments.filter { pendingComment in
            guard let commentId = pendingComment.commentId else { return true }
            return !existingIds.contains(commentId)
        })

        return comments.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }

    static func fetchCommentCount(forThreadId threadId: String) async throws -> Int {
        let snapshot = try await db.collection("threads")
            .document(threadId)
            .collection("comments")
            .getDocuments()

        return snapshot.documents.count
    }
}
