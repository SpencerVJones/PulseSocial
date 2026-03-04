//
//  OfflineSyncService.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Foundation
import Firebase
import FirebaseAuth

enum PendingSyncOperationKind: String, Codable {
    case createThread
    case likeThread
    case unlikeThread
    case addComment
}

private struct CachedThreadRecord: Codable {
    let threadId: String?
    let operationId: String?
    let ownerUid: String
    let caption: String
    let createdAt: Date
    let likes: Int
    let ownerUsername: String?
    let ownerProfileImageUrl: String?
    let circleId: String?
    let circleName: String?
    let promptId: String?
    let promptTitle: String?
    let voiceClipUrl: String?
    let voiceClipDuration: Double?
    let isRepost: Bool
    let repostedThreadId: String?
    let reactionCounts: [String: Int]
    let currentUserReaction: String?
    let imageUrl: String?
    let commentCount: Int
    let didLike: Bool
    let user: User?
    let isPendingSync: Bool

    init(thread: Thread, isPendingSync: Bool? = nil) {
        self.threadId = thread.threadId
        self.operationId = thread.operationId
        self.ownerUid = thread.ownerUid
        self.caption = thread.caption
        self.createdAt = thread.timestamp.dateValue()
        self.likes = thread.likes
        self.ownerUsername = thread.ownerUsername
        self.ownerProfileImageUrl = thread.ownerProfileImageUrl
        self.circleId = thread.circleId
        self.circleName = thread.circleName
        self.promptId = thread.promptId
        self.promptTitle = thread.promptTitle
        self.voiceClipUrl = thread.voiceClipUrl
        self.voiceClipDuration = thread.voiceClipDuration
        self.isRepost = thread.isRepost ?? false
        self.repostedThreadId = thread.repostedThreadId
        self.reactionCounts = thread.resolvedReactionCounts
        self.currentUserReaction = thread.currentUserReaction?.rawValue
        self.imageUrl = thread.imageUrl
        self.commentCount = thread.resolvedCommentCount
        self.didLike = thread.didLike ?? false
        self.user = thread.user
        self.isPendingSync = isPendingSync ?? thread.isPendingSync
    }

    var thread: Thread {
        var thread = Thread(
            threadId: threadId,
            ownerUid: ownerUid,
            operationId: operationId,
            caption: caption,
            timestamp: Timestamp(date: createdAt),
            likes: likes,
            ownerUsername: ownerUsername,
            ownerProfileImageUrl: ownerProfileImageUrl,
            circleId: circleId,
            circleName: circleName,
            promptId: promptId,
            promptTitle: promptTitle,
            voiceClipUrl: voiceClipUrl,
            voiceClipDuration: voiceClipDuration,
            isRepost: isRepost,
            repostedThreadId: repostedThreadId,
            reactionCounts: reactionCounts,
            currentUserReaction: currentUserReaction.flatMap(ThreadReactionType.init(rawValue:)),
            imageUrl: imageUrl,
            commentCount: commentCount,
            didLike: didLike
        )

        thread.user = user
        thread.isPendingSync = isPendingSync
        return thread
    }
}

private struct PendingLikeTarget: Codable {
    let threadId: String
    let ownerUid: String
}

private struct PendingCommentPayload: Codable {
    let operationId: String
    let ownerUid: String
    let threadId: String
    let threadOwnerUid: String
    let commentText: String
    let createdAt: Date
    let ownerUsername: String?
    let ownerProfileImageUrl: String?
    let voiceClipUrl: String?
    let voiceClipDuration: Double?
}

private struct PendingSyncOperation: Identifiable, Codable {
    let id: String
    let actorUid: String
    let createdAt: Date
    let kind: PendingSyncOperationKind
    var threadRecord: CachedThreadRecord?
    var likeTarget: PendingLikeTarget?
    var commentPayload: PendingCommentPayload?
}

actor OfflineSyncService {
    static let shared = OfflineSyncService()

    private let defaults = UserDefaults.standard
    private let queueKey = "pulse.pendingSyncOperations"
    private let cacheKey = "pulse.cachedFeedThreads"

    func cachedThreads() -> [Thread] {
        decode([CachedThreadRecord].self, forKey: cacheKey)?.map(\.thread) ?? []
    }

    func saveCachedThreads(_ threads: [Thread]) async {
        let records = threads.map { CachedThreadRecord(thread: $0, isPendingSync: false) }
        encode(records, forKey: cacheKey)
    }

    func pendingThreads(for ownerUid: String? = nil) -> [Thread] {
        pendingOperations()
            .filter { $0.kind == .createThread }
            .compactMap(\.threadRecord)
            .map(\.thread)
            .filter { ownerUid == nil || $0.ownerUid == ownerUid }
            .sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }

    func pendingComments(forThreadId threadId: String) -> [ThreadComment] {
        pendingOperations()
            .filter { $0.kind == .addComment }
            .compactMap(\.commentPayload)
            .filter { $0.threadId == threadId }
            .map(comment(from:))
            .sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }

    func pendingComments(forOwnerUid ownerUid: String) -> [ThreadComment] {
        pendingOperations()
            .filter { $0.actorUid == ownerUid && $0.kind == .addComment }
            .compactMap(\.commentPayload)
            .map(comment(from:))
            .sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }

    func mergedThreads(withRemote remoteThreads: [Thread]) -> [Thread] {
        let pending = pendingThreads()
        guard !pending.isEmpty else { return remoteThreads }

        let remoteIds = Set(remoteThreads.compactMap(\.threadId))
        let remoteOperationIds = Set(remoteThreads.compactMap(\.operationId))

        let unresolvedPending = pending.filter { pendingThread in
            if let threadId = pendingThread.threadId, remoteIds.contains(threadId) {
                return false
            }

            if let operationId = pendingThread.operationId, remoteOperationIds.contains(operationId) {
                return false
            }

            return true
        }

        return unresolvedPending + remoteThreads
    }

    func pendingOperationCount() -> Int {
        pendingOperations().count
    }

    @discardableResult
    func syncPendingOperations() async -> Int {
        let queued = pendingOperations().sorted { $0.createdAt < $1.createdAt }
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return queued.count
        }

        var remaining = [PendingSyncOperation]()

        for operation in queued {
            guard operation.actorUid == currentUid else {
                remaining.append(operation)
                continue
            }

            do {
                try await process(operation)
            } catch {
                remaining.append(operation)
            }
        }

        savePendingOperations(remaining)
        return remaining.count
    }

    func enqueueThreadCreation(_ thread: Thread) async {
        guard let actorUid = Auth.auth().currentUser?.uid else { return }

        var queued = pendingOperations()
        let operationId = thread.operationId ?? UUID().uuidString

        guard !queued.contains(where: { $0.id == operationId }) else { return }

        var pendingThread = thread
        pendingThread.operationId = operationId
        pendingThread.isPendingSync = true

        queued.append(
            PendingSyncOperation(
                id: operationId,
                actorUid: actorUid,
                createdAt: pendingThread.timestamp.dateValue(),
                kind: .createThread,
                threadRecord: CachedThreadRecord(thread: pendingThread, isPendingSync: true),
                likeTarget: nil,
                commentPayload: nil
            )
        )
        savePendingOperations(queued)
    }

    func enqueueLike(for thread: Thread, shouldLike: Bool) async {
        guard
            let actorUid = Auth.auth().currentUser?.uid,
            let targetId = thread.threadId ?? thread.operationId
        else { return }

        var queued = pendingOperations()
        queued.removeAll {
            guard $0.actorUid == actorUid, let likeTarget = $0.likeTarget else { return false }
            return likeTarget.threadId == targetId && ($0.kind == .likeThread || $0.kind == .unlikeThread)
        }

        queued.append(
            PendingSyncOperation(
                id: UUID().uuidString,
                actorUid: actorUid,
                createdAt: Date(),
                kind: shouldLike ? .likeThread : .unlikeThread,
                threadRecord: nil,
                likeTarget: PendingLikeTarget(threadId: targetId, ownerUid: thread.ownerUid),
                commentPayload: nil
            )
        )

        savePendingOperations(queued)
    }

    func enqueueComment(
        for thread: Thread,
        text: String,
        voiceClipUrl: String?,
        voiceClipDuration: Double?,
        operationId: String
    ) async {
        guard
            let actorUid = Auth.auth().currentUser?.uid,
            let threadId = thread.threadId ?? thread.operationId
        else { return }

        let payload = PendingCommentPayload(
            operationId: operationId,
            ownerUid: actorUid,
            threadId: threadId,
            threadOwnerUid: thread.ownerUid,
            commentText: text,
            createdAt: Date(),
            ownerUsername: UserService.shared.currentUser?.username,
            ownerProfileImageUrl: UserService.shared.currentUser?.profileImageUrl,
            voiceClipUrl: voiceClipUrl,
            voiceClipDuration: voiceClipDuration
        )

        var queued = pendingOperations()
        queued.append(
            PendingSyncOperation(
                id: operationId,
                actorUid: actorUid,
                createdAt: payload.createdAt,
                kind: .addComment,
                threadRecord: nil,
                likeTarget: nil,
                commentPayload: payload
            )
        )
        savePendingOperations(queued)
    }

    func removePendingCreateThread(operationId: String) {
        var queued = pendingOperations()
        queued.removeAll { $0.kind == .createThread && $0.id == operationId }
        savePendingOperations(queued)
    }

    private func process(_ operation: PendingSyncOperation) async throws {
        switch operation.kind {
        case .createThread:
            guard let threadRecord = operation.threadRecord else { return }
            try await ThreadService.uploadThreadRemotely(threadRecord.thread, preferredDocumentId: operation.id)

        case .likeThread:
            guard let target = operation.likeTarget else { return }
            try await ThreadLikeService.performLikeRemotely(
                threadId: target.threadId,
                threadOwnerUid: target.ownerUid
            )

        case .unlikeThread:
            guard let target = operation.likeTarget else { return }
            try await ThreadLikeService.performUnlikeRemotely(threadId: target.threadId)

        case .addComment:
            guard let payload = operation.commentPayload else { return }
            try await CommentService.addCommentRemotely(
                threadId: payload.threadId,
                threadOwnerUid: payload.threadOwnerUid,
                text: payload.commentText,
                voiceClipUrl: payload.voiceClipUrl,
                voiceClipDuration: payload.voiceClipDuration,
                ownerUsername: payload.ownerUsername,
                ownerProfileImageUrl: payload.ownerProfileImageUrl,
                operationId: payload.operationId,
                timestamp: Timestamp(date: payload.createdAt)
            )
        }
    }

    private func pendingOperations() -> [PendingSyncOperation] {
        decode([PendingSyncOperation].self, forKey: queueKey) ?? []
    }

    private func comment(from payload: PendingCommentPayload) -> ThreadComment {
        var comment = ThreadComment(
            threadId: payload.threadId,
            ownerUid: payload.ownerUid,
            commentText: payload.commentText,
            timestamp: Timestamp(date: payload.createdAt),
            ownerUsername: payload.ownerUsername,
            ownerProfileImageUrl: payload.ownerProfileImageUrl,
            voiceClipUrl: payload.voiceClipUrl,
            voiceClipDuration: payload.voiceClipDuration
        )
        comment.commentId = payload.operationId
        comment.isPendingSync = true
        return comment
    }

    private func savePendingOperations(_ operations: [PendingSyncOperation]) {
        encode(operations, forKey: queueKey)

        Task { @MainActor in
            NotificationCenter.default.post(name: .syncQueueDidChange, object: nil)
        }
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }
}
