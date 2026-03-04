//
//  PulseTests.swift
//  PulseTests
//
//  Created by Codex on 2/18/26.
//

import XCTest
import Firebase
@testable import Pulse

@MainActor
final class ThreadCellViewModelTests: XCTestCase {
    func testToggleLikeWhenNotLikedIncrementsLikeCount() async {
        let mockService = MockLikeService()
        var thread = DeveloperPreview.shared.thread
        thread.likes = 1
        thread.didLike = false

        let viewModel = ThreadCellViewModel(thread: thread, likeService: mockService)
        await viewModel.toggleLike()

        XCTAssertEqual(viewModel.thread.likes, 2)
        XCTAssertEqual(viewModel.thread.didLike, true)
        XCTAssertEqual(mockService.likeCallCount, 1)
        XCTAssertEqual(mockService.unlikeCallCount, 0)
    }

    func testToggleLikeWhenLikedDecrementsLikeCount() async {
        let mockService = MockLikeService()
        var thread = DeveloperPreview.shared.thread
        thread.likes = 3
        thread.didLike = true

        let viewModel = ThreadCellViewModel(thread: thread, likeService: mockService)
        await viewModel.toggleLike()

        XCTAssertEqual(viewModel.thread.likes, 2)
        XCTAssertEqual(viewModel.thread.didLike, false)
        XCTAssertEqual(mockService.likeCallCount, 0)
        XCTAssertEqual(mockService.unlikeCallCount, 1)
    }
}

@MainActor
final class UserFollowViewModelTests: XCTestCase {
    func testToggleFollowFromFalseSetsTrue() async {
        let mockService = MockFollowService(isFollowing: false)
        var user = DeveloperPreview.shared.user
        user.isFollowed = false

        let viewModel = UserFollowViewModel(user: user, followService: mockService)
        await viewModel.toggleFollow()

        XCTAssertEqual(viewModel.isFollowing, true)
        XCTAssertEqual(mockService.followCallCount, 1)
        XCTAssertEqual(mockService.unfollowCallCount, 0)
    }

    func testThemeMappingValues() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }
}

private final class MockLikeService: ThreadLikeServicing {
    var likeCallCount = 0
    var unlikeCallCount = 0

    func like(_ thread: Pulse.Thread) async throws {
        likeCallCount += 1
    }

    func unlike(_ thread: Pulse.Thread) async throws {
        unlikeCallCount += 1
    }

    func didLike(_ thread: Pulse.Thread) async throws -> Bool {
        thread.didLike ?? false
    }
}

private final class MockFollowService: FollowServicing {
    private(set) var followCallCount = 0
    private(set) var unfollowCallCount = 0
    private var isCurrentlyFollowing: Bool

    init(isFollowing: Bool) {
        self.isCurrentlyFollowing = isFollowing
    }

    func follow(uid: String) async throws {
        followCallCount += 1
        isCurrentlyFollowing = true
    }

    func unfollow(uid: String) async throws {
        unfollowCallCount += 1
        isCurrentlyFollowing = false
    }

    func isFollowing(uid: String) async throws -> Bool {
        isCurrentlyFollowing
    }

    func fetchFollowerCount(for uid: String) async throws -> Int {
        0
    }

    func fetchFollowingCount(for uid: String) async throws -> Int {
        0
    }
}

final class FeedRankingServiceTests: XCTestCase {
    func testRankedFeedPrioritizesRelationshipSignals() {
        let viewerId = "viewer"

        var followedThread = Thread(
            ownerUid: "followed-user",
            operationId: "rank-1",
            caption: "Followed user update",
            timestamp: Timestamp(date: Date().addingTimeInterval(-7_200)),
            likes: 6,
            commentCount: 3
        )
        followedThread.threadId = "rank-1"

        var randomThread = Thread(
            ownerUid: "random-user",
            operationId: "rank-2",
            caption: "Random user update",
            timestamp: Timestamp(date: Date().addingTimeInterval(-600)),
            likes: 1,
            commentCount: 0
        )
        randomThread.threadId = "rank-2"

        let ranked = FeedRankingService.rank(
            [randomThread, followedThread],
            viewerId: viewerId,
            followingIds: ["followed-user"],
            closeFriendIds: []
        )

        XCTAssertEqual(ranked.first?.ownerUid, "followed-user")
        XCTAssertNotNil(ranked.first?.rankingScore)
    }

    func testRankedFeedUsesStableNewestTieBreak() {
        var olderThread = Thread(
            ownerUid: "same-user",
            operationId: "rank-older",
            caption: "Older",
            timestamp: Timestamp(date: Date().addingTimeInterval(-1_800)),
            likes: 0,
            commentCount: 0
        )
        olderThread.threadId = "rank-older"

        var newerThread = Thread(
            ownerUid: "same-user",
            operationId: "rank-newer",
            caption: "Newer",
            timestamp: Timestamp(date: Date().addingTimeInterval(-60)),
            likes: 0,
            commentCount: 0
        )
        newerThread.threadId = "rank-newer"

        let ranked = FeedRankingService.rank(
            [olderThread, newerThread],
            viewerId: nil,
            followingIds: [],
            closeFriendIds: []
        )

        XCTAssertEqual(ranked.first?.threadId, "rank-newer")
    }
}
