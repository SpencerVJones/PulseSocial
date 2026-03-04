//
//  ThreadCellViewModel.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import Foundation

@MainActor
final class ThreadCellViewModel: ObservableObject {
    @Published var thread: Thread
    @Published private(set) var referencedThread: Thread?
    @Published var repostAlertMessage = ""
    @Published var showRepostAlert = false
    @Published var deleteAlertMessage = ""
    @Published var showDeleteAlert = false
    private let likeService: ThreadLikeServicing

    init(thread: Thread, likeService: ThreadLikeServicing = LiveThreadLikeService()) {
        self.thread = thread
        self.likeService = likeService
    }

    var isRepostWrapper: Bool {
        thread.isRepost == true
    }

    var displayThread: Thread {
        referencedThread ?? thread
    }

    var canDeleteCurrentItem: Bool {
        threadForDeletion.ownerUid == UserService.shared.currentUser?.id
    }

    var deleteActionTitle: String {
        isRepostWrapper ? "Delete Repost" : "Delete Post"
    }

    func updateThread(_ updatedThread: Thread) {
        thread = updatedThread
        if updatedThread.isRepost != true {
            referencedThread = nil
        }
    }

    func prepareForDisplay() async {
        await loadReferencedThreadIfNeeded()
        if displayThread.didLike == nil {
            await refreshLikeState()
        }
    }

    func refreshLikeState() async {
        do {
            let didLike = try await likeService.didLike(displayThread)
            updateDisplayThread { $0.didLike = didLike }
        } catch {
            print("DEBUG: Failed to refresh like state: \(error.localizedDescription)")
        }
    }

    func toggleLike() async {
        do {
            if displayThread.didLike == true {
                try await likeService.unlike(displayThread)
                updateDisplayThread {
                    $0.likes = max($0.likes - 1, 0)
                    $0.didLike = false
                }
            } else {
                try await likeService.like(displayThread)
                updateDisplayThread {
                    $0.likes += 1
                    $0.didLike = true
                }
            }
        } catch {
            print("DEBUG: Failed to toggle like: \(error.localizedDescription)")
        }
    }

    func setCommentCount(_ count: Int) {
        updateDisplayThread { $0.commentCount = count }
    }

    func setReaction(_ reaction: ThreadReactionType) async {
        do {
            let currentThread = displayThread
            let previousReaction = currentThread.currentUserReaction
            try await ThreadReactionService.setReaction(reaction, on: currentThread)

            var counts = currentThread.resolvedReactionCounts

            if let previousReaction {
                counts[previousReaction.rawValue] = max((counts[previousReaction.rawValue] ?? 0) - 1, 0)
            }

            if previousReaction == reaction {
                updateDisplayThread {
                    $0.currentUserReaction = nil
                    $0.reactionCounts = counts
                }
            } else {
                counts[reaction.rawValue] = (counts[reaction.rawValue] ?? 0) + 1
                updateDisplayThread {
                    $0.currentUserReaction = reaction
                    $0.reactionCounts = counts
                }
            }
        } catch {
            print("DEBUG: Failed to set reaction: \(error.localizedDescription)")
        }
    }

    func repostThread() async {
        do {
            try await ThreadService.repost(displayThread)
            NotificationCenter.default.post(name: .postDidPublish, object: nil)
        } catch {
            repostAlertMessage = error.localizedDescription
            showRepostAlert = true
            print("DEBUG: Failed to repost post: \(error.localizedDescription)")
        }
    }

    func deleteCurrentItem() async {
        do {
            try await ThreadService.deleteThread(threadForDeletion)
            NotificationCenter.default.post(name: .postDidPublish, object: nil)
        } catch {
            deleteAlertMessage = error.localizedDescription
            showDeleteAlert = true
            print("DEBUG: Failed to delete post: \(error.localizedDescription)")
        }
    }

    private func loadReferencedThreadIfNeeded() async {
        guard isRepostWrapper, let repostedThreadId = thread.repostedThreadId else { return }
        guard referencedThread?.threadId != repostedThreadId else { return }

        do {
            guard var fetchedThread = try await ThreadService.fetchThread(withId: repostedThreadId) else {
                referencedThread = nil
                return
            }

            if fetchedThread.ownerUid == UserService.shared.currentUser?.id {
                fetchedThread.user = UserService.shared.currentUser
            } else {
                fetchedThread.user = try? await UserService.fetchUser(withUid: fetchedThread.ownerUid)
            }

            referencedThread = fetchedThread
        } catch {
            print("DEBUG: Failed to load reposted post: \(error.localizedDescription)")
        }
    }

    private func updateDisplayThread(_ mutation: (inout Thread) -> Void) {
        if var referencedThread {
            mutation(&referencedThread)
            self.referencedThread = referencedThread
        } else {
            mutation(&thread)
        }
    }

    private var threadForDeletion: Thread {
        isRepostWrapper ? thread : displayThread
    }
}
