//
//  FeedRankingService.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Foundation

struct FeedRankingService {
    private static let recencyWeight = 0.40
    private static let relationshipWeight = 0.25
    private static let engagementWeight = 0.20
    private static let circleWeight = 0.15
    private static let recencyDecayHours = 18.0

    static func rank(
        _ threads: [Thread],
        viewerId: String?,
        followingIds: Set<String>,
        closeFriendIds: Set<String>
    ) -> [Thread] {
        guard !threads.isEmpty else { return [] }

        let circleHistory = circleAffinityLookup(for: threads, viewerId: viewerId)

        let scoredThreads = threads.map { thread -> Thread in
            let recency = recencyScore(for: thread)
            let relationship = relationshipScore(
                for: thread,
                viewerId: viewerId,
                followingIds: followingIds,
                closeFriendIds: closeFriendIds
            )
            let engagement = engagementVelocityScore(for: thread)
            let circleAffinity = circleAffinityScore(for: thread, lookup: circleHistory)

            let score =
                (recencyWeight * recency) +
                (relationshipWeight * relationship) +
                (engagementWeight * engagement) +
                (circleWeight * circleAffinity)

            var rankedThread = thread
            rankedThread.rankingScore = score
            return rankedThread
        }

        return scoredThreads.sorted { lhs, rhs in
            let lhsScore = lhs.rankingScore ?? 0
            let rhsScore = rhs.rankingScore ?? 0

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            let lhsDate = lhs.timestamp.dateValue()
            let rhsDate = rhs.timestamp.dateValue()
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }

            let lhsId = lhs.threadId ?? lhs.operationId ?? ""
            let rhsId = rhs.threadId ?? rhs.operationId ?? ""
            return lhsId > rhsId
        }
    }

    private static func recencyScore(for thread: Thread) -> Double {
        let ageHours = max(Date().timeIntervalSince(thread.timestamp.dateValue()) / 3600, 0)
        return Foundation.exp(-ageHours / recencyDecayHours)
    }

    private static func relationshipScore(
        for thread: Thread,
        viewerId: String?,
        followingIds: Set<String>,
        closeFriendIds: Set<String>
    ) -> Double {
        if thread.ownerUid == viewerId {
            return 1.0
        }

        if closeFriendIds.contains(thread.ownerUid) {
            return 0.9
        }

        if followingIds.contains(thread.ownerUid) {
            return 0.7
        }

        if thread.didLike == true || thread.currentUserReaction != nil {
            return 0.45
        }

        return 0.2
    }

    private static func engagementVelocityScore(for thread: Thread) -> Double {
        let ageHours = max(Date().timeIntervalSince(thread.timestamp.dateValue()) / 3600, 1)
        let reactions = Double(thread.resolvedReactionCounts.values.reduce(0, +))
        let weightedEngagement =
            Double(thread.likes) +
            (Double(thread.resolvedCommentCount) * 1.5) +
            (reactions * 0.75)
        let velocity = weightedEngagement / ageHours
        return min(velocity / 12.0, 1.0)
    }

    private static func circleAffinityLookup(
        for threads: [Thread],
        viewerId: String?
    ) -> [String: Double] {
        guard let viewerId else { return [:] }

        let ownedThreads = threads.filter { $0.ownerUid == viewerId }
        let grouped = Dictionary(grouping: ownedThreads.compactMap { thread -> String? in
            thread.circleId
        }, by: { $0 })

        let maxCount = max(grouped.values.map(\.count).max() ?? 0, 1)

        return grouped.reduce(into: [String: Double]()) { result, entry in
            result[entry.key] = Double(entry.value.count) / Double(maxCount)
        }
    }

    private static func circleAffinityScore(
        for thread: Thread,
        lookup: [String: Double]
    ) -> Double {
        guard let circleId = thread.circleId else { return 0.1 }
        return lookup[circleId] ?? 0.2
    }
}
