//  ThreadService.swift
//  Pulse
//  Created by Spencer Jones on 6/13/25

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

enum ThreadServiceError: LocalizedError {
    case missingAuthenticatedUser
    case missingThreadIdentifier
    case alreadyReposted
    case unauthorizedDelete

    var errorDescription: String? {
        switch self {
        case .missingAuthenticatedUser:
            return "You must be signed in to repost."
        case .missingThreadIdentifier:
            return "This post can't be reposted right now."
        case .alreadyReposted:
            return "You already reposted this post."
        case .unauthorizedDelete:
            return "You can only delete your own posts."
        }
    }
}

struct ThreadService {
    static func uploadThread(_ thread: Thread) async throws {
        var preparedThread = thread
        if preparedThread.operationId == nil {
            preparedThread.operationId = UUID().uuidString
        }

        do {
            try await uploadThreadRemotely(preparedThread, preferredDocumentId: preparedThread.operationId)
        } catch {
            await OfflineSyncService.shared.enqueueThreadCreation(preparedThread)
        }
    }

    static func uploadThreadRemotely(_ thread: Thread, preferredDocumentId: String? = nil) async throws {
        let documentId = preferredDocumentId ?? thread.threadId ?? thread.operationId ?? UUID().uuidString
        let threadRef = Firestore.firestore().collection("threads").document(documentId)

        let existingSnapshot = try await threadRef.getDocument()
        if existingSnapshot.exists {
            return
        }

        var threadToPersist = thread
        threadToPersist.isPendingSync = false
        threadToPersist.rankingScore = nil

        guard let threadData = try? Firestore.Encoder().encode(threadToPersist) else { return }
        try await threadRef.setData(threadData)
    }
    
    static func fetchThreads() async throws -> [Thread] {
        let snapshot = try await Firestore.firestore().collection("threads").order(by: "timestamp", descending: true).getDocuments()
        
        // Map snapshot into thread arraw
        var threads = snapshot.documents.compactMap({ try? $0.data(as: Thread.self) })

        for index in threads.indices {
            threads[index].didLike = try await ThreadLikeService.didLike(threads[index])
            threads[index].currentUserReaction = try await ThreadReactionService.fetchCurrentUserReaction(for: threads[index])
            if threads[index].commentCount == nil, let threadId = threads[index].threadId {
                threads[index].commentCount = try await CommentService.fetchCommentCount(forThreadId: threadId)
            }
        }

        return threads
    }
    
    static func fetchUserTreads(uid: String) async throws -> [Thread] {
        let snapshot = try await Firestore.firestore().collection("threads").whereField("ownerUid", isEqualTo: uid).getDocuments()
        var threads = snapshot.documents.compactMap({ try? $0.data(as: Thread.self)})

        for index in threads.indices {
            threads[index].didLike = try await ThreadLikeService.didLike(threads[index])
            threads[index].currentUserReaction = try await ThreadReactionService.fetchCurrentUserReaction(for: threads[index])
            if threads[index].commentCount == nil, let threadId = threads[index].threadId {
                threads[index].commentCount = try await CommentService.fetchCommentCount(forThreadId: threadId)
            }
        }

        let pendingThreads = await OfflineSyncService.shared.pendingThreads(for: uid)
        let remoteOperationIds = Set(threads.compactMap(\.operationId))
        let mergedPending = pendingThreads.filter { pendingThread in
            guard let operationId = pendingThread.operationId else { return true }
            return !remoteOperationIds.contains(operationId)
        }

        threads.append(contentsOf: mergedPending)
        return threads.sorted(by: {$0.timestamp.dateValue() > $1.timestamp.dateValue()})
    }

    static func fetchThread(withId threadId: String) async throws -> Thread? {
        let snapshot = try await Firestore.firestore().collection("threads").document(threadId).getDocument()
        guard snapshot.exists else { return nil }
        guard var thread = try? snapshot.data(as: Thread.self) else { return nil }
        thread.didLike = try? await ThreadLikeService.didLike(thread)
        thread.currentUserReaction = try? await ThreadReactionService.fetchCurrentUserReaction(for: thread)
        if thread.commentCount == nil, let threadId = thread.threadId {
            thread.commentCount = try? await CommentService.fetchCommentCount(forThreadId: threadId)
        }
        return thread
    }

    static func repost(_ sourceThread: Thread) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ThreadServiceError.missingAuthenticatedUser
        }

        let repostSource = resolveRepostSource(for: sourceThread)

        guard let repostedThreadId = repostSource.canonicalThreadId else {
            throw ThreadServiceError.missingThreadIdentifier
        }

        if try await hasExistingRepost(by: currentUid, matching: repostSource.duplicateCheckThreadIds) {
            throw ThreadServiceError.alreadyReposted
        }

        let repost = Thread(
            ownerUid: currentUid,
            operationId: UUID().uuidString,
            caption: sourceThread.caption,
            timestamp: Timestamp(),
            likes: 0,
            ownerUsername: UserService.shared.currentUser?.username,
            ownerProfileImageUrl: UserService.shared.currentUser?.profileImageUrl,
            circleId: sourceThread.circleId,
            circleName: sourceThread.circleName,
            promptId: sourceThread.promptId,
            promptTitle: sourceThread.promptTitle,
            voiceClipUrl: sourceThread.voiceClipUrl,
            voiceClipDuration: sourceThread.voiceClipDuration,
            isRepost: true,
            repostedThreadId: repostedThreadId,
            reactionCounts: [:],
            currentUserReaction: nil,
            imageUrl: sourceThread.imageUrl,
            commentCount: 0,
            didLike: nil
        )

        try await uploadThread(repost)
    }

    static func deleteThread(_ thread: Thread) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ThreadServiceError.missingAuthenticatedUser
        }

        if thread.isPendingSync, let operationId = thread.operationId {
            guard thread.ownerUid == currentUid else {
                throw ThreadServiceError.unauthorizedDelete
            }

            await OfflineSyncService.shared.removePendingCreateThread(operationId: operationId)
            return
        }

        guard let threadId = thread.threadId else {
            throw ThreadServiceError.missingThreadIdentifier
        }

        guard thread.ownerUid == currentUid else {
            throw ThreadServiceError.unauthorizedDelete
        }

        let threadRef = Firestore.firestore().collection("threads").document(threadId)

        async let deleteCommentsTask: Void = deleteDocuments(in: threadRef.collection("comments"))
        async let deleteLikesTask: Void = deleteDocuments(in: threadRef.collection("thread-likes"))
        async let deleteReactionsTask: Void = deleteDocuments(in: threadRef.collection("thread-reactions"))
        async let deleteNotificationsTask: Void = deleteThreadNotifications(
            forThreadId: threadId,
            ownerUid: thread.ownerUid
        )

        _ = try await (deleteCommentsTask, deleteLikesTask, deleteReactionsTask, deleteNotificationsTask)
        try await threadRef.delete()
    }

    private static func resolveRepostSource(for sourceThread: Thread) -> (canonicalThreadId: String?, duplicateCheckThreadIds: Set<String>) {
        let canonicalThreadId: String?
        if sourceThread.isRepost == true {
            canonicalThreadId = sourceThread.repostedThreadId ?? sourceThread.threadId
        } else {
            canonicalThreadId = sourceThread.threadId
        }

        var duplicateCheckThreadIds = Set<String>()
        if let canonicalThreadId {
            duplicateCheckThreadIds.insert(canonicalThreadId)
        }
        if let threadId = sourceThread.threadId {
            duplicateCheckThreadIds.insert(threadId)
        }

        return (canonicalThreadId, duplicateCheckThreadIds)
    }

    private static func hasExistingRepost(by uid: String, matching threadIds: Set<String>) async throws -> Bool {
        guard !threadIds.isEmpty else { return false }

        let snapshot = try await Firestore.firestore()
            .collection("threads")
            .whereField("ownerUid", isEqualTo: uid)
            .whereField("isRepost", isEqualTo: true)
            .getDocuments()

        return snapshot.documents.contains { document in
            guard let repostedThreadId = document.data()["repostedThreadId"] as? String else {
                return false
            }

            return threadIds.contains(repostedThreadId)
        }
    }

    private static func deleteDocuments(in collection: CollectionReference) async throws {
        let snapshot = try await collection.getDocuments()

        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }

    private static func deleteThreadNotifications(forThreadId threadId: String, ownerUid: String) async throws {
        let snapshot = try await Firestore.firestore()
            .collection("notifications")
            .document(ownerUid)
            .collection("user-notifications")
            .whereField("threadId", isEqualTo: threadId)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
}
