//  Thread.swift
//  Pulse
//  Created by Spencer Jones on 6/13/25

import Foundation
import Firebase
import FirebaseFirestore

struct Thread: Identifiable, Codable {
    @DocumentID var threadId: String?
    let ownerUid: String // Pointer to user that owns the thread
    var operationId: String? = nil
    let caption: String
    let timestamp: Timestamp
    var likes: Int
    var ownerUsername: String? = nil
    var ownerProfileImageUrl: String? = nil
    var circleId: String? = nil
    var circleName: String? = nil
    var promptId: String? = nil
    var promptTitle: String? = nil
    var voiceClipUrl: String? = nil
    var voiceClipDuration: Double? = nil
    var isRepost: Bool? = false
    var repostedThreadId: String? = nil
    var reactionCounts: [String: Int]? = [:]
    var currentUserReaction: ThreadReactionType? = nil
    var imageUrl: String? = nil
    var commentCount: Int? = 0
    var didLike: Bool? = nil

    var id: String {
        threadId ?? operationId ?? NSUUID().uuidString
    }
    
    var user: User? = nil
    var isPendingSync = false
    var rankingScore: Double? = nil

    var resolvedCommentCount: Int {
        commentCount ?? 0
    }

    var resolvedReactionCounts: [String: Int] {
        reactionCounts ?? [:]
    }

    // Used by SwiftUI cells to detect upstream thread updates (user info, counts, media, etc).
    var syncKey: String {
        let userId = user?.id ?? ""
        let username = user?.username ?? ""
        let profileImageUrl = user?.profileImageUrl ?? ""
        let fallbackUsername = ownerUsername ?? ""
        let fallbackProfileImageUrl = ownerProfileImageUrl ?? ""
        let circleIdentifier = circleId ?? ""
        let circleTitle = circleName ?? ""
        let promptIdentifier = promptId ?? ""
        let promptValue = promptTitle ?? ""
        let voiceValue = voiceClipUrl ?? ""
        let voiceDurationValue = voiceClipDuration.map { String($0) } ?? ""
        let repostValue = isRepost == true ? "1" : "0"
        let repostedThreadIdentifier = repostedThreadId ?? ""
        let reactionValue = (currentUserReaction?.rawValue ?? "")
            + (resolvedReactionCounts.sorted(by: { $0.key < $1.key })
                .map { "\($0.key):\($0.value)" }
                .joined(separator: ","))
        let didLikeValue = didLike == true ? "1" : "0"
        let imageValue = imageUrl ?? ""
        let threadIdentifier = threadId ?? ""
        let operationIdentifier = operationId ?? ""
        let pendingValue = isPendingSync ? "1" : "0"
        let rankingValue = rankingScore.map { String(format: "%.4f", $0) } ?? ""
        return [
            threadIdentifier,
            operationIdentifier,
            ownerUid,
            caption,
            String(timestamp.seconds),
            String(timestamp.nanoseconds),
            String(likes),
            String(resolvedCommentCount),
            didLikeValue,
            reactionValue,
            imageValue,
            circleIdentifier,
            circleTitle,
            promptIdentifier,
            promptValue,
            voiceValue,
            voiceDurationValue,
            repostValue,
            repostedThreadIdentifier,
            userId,
            username,
            profileImageUrl,
            pendingValue,
            rankingValue,
            fallbackUsername,
            fallbackProfileImageUrl
        ].joined(separator: "|")
    }

    enum CodingKeys: String, CodingKey {
        case threadId
        case ownerUid
        case operationId
        case caption
        case timestamp
        case likes
        case ownerUsername
        case ownerProfileImageUrl
        case circleId
        case circleName
        case promptId
        case promptTitle
        case voiceClipUrl
        case voiceClipDuration
        case isRepost
        case repostedThreadId
        case reactionCounts
        case currentUserReaction
        case imageUrl
        case commentCount
        case didLike
    }
}
