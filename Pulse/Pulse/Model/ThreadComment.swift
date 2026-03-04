//
//  ThreadComment.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import Firebase
import FirebaseFirestore

struct ThreadComment: Identifiable, Codable {
    @DocumentID var commentId: String?
    let threadId: String
    let ownerUid: String
    let commentText: String
    let timestamp: Timestamp
    var ownerUsername: String? = nil
    var ownerProfileImageUrl: String? = nil
    var voiceClipUrl: String? = nil
    var voiceClipDuration: Double? = nil

    var user: User?
    var isPendingSync = false

    var id: String {
        commentId ?? UUID().uuidString
    }

    enum CodingKeys: String, CodingKey {
        case commentId
        case threadId
        case ownerUid
        case commentText
        case timestamp
        case ownerUsername
        case ownerProfileImageUrl
        case voiceClipUrl
        case voiceClipDuration
    }
}
