//
//  ChatThread.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Firebase
import FirebaseFirestore

enum ChatThreadType: String, Codable, CaseIterable, Identifiable {
    case dm
    case group

    var id: String { rawValue }
}

enum ChatMemberRole: String, Codable {
    case member
    case admin
}

enum ChatMemberState: String, Codable, CaseIterable, Identifiable {
    case active
    case requested
    case blocked

    var id: String { rawValue }
}

enum ChatMessageType: String, Codable, CaseIterable, Identifiable {
    case text
    case image
    case file
    case audio

    var id: String { rawValue }
}

struct ChatThread: Identifiable, Codable, Hashable {
    @DocumentID var threadId: String?
    let type: ChatThreadType
    let createdAt: Timestamp
    let createdBy: String
    var memberIds: [String]
    var title: String?
    var photoURL: String?
    var lastMessageText: String?
    var lastMessageAt: Timestamp?
    var lastMessageType: ChatMessageType?
    var lastMessageSenderId: String?

    var id: String {
        threadId ?? UUID().uuidString
    }
}

struct ChatThreadMember: Identifiable, Codable, Hashable {
    @DocumentID var memberId: String?
    let role: ChatMemberRole
    let joinedAt: Timestamp
    var lastReadAt: Timestamp?
    var mute: Bool
    var archived: Bool
    var state: ChatMemberState
    var requestedBy: String?
    var acceptedAt: Timestamp?
    var deletedAt: Timestamp?

    var id: String {
        memberId ?? UUID().uuidString
    }
}

struct ChatMessageMedia: Codable, Hashable {
    let url: String
    var thumbUrl: String?
    var fileName: String?
    var mimeType: String?
    var sizeBytes: Int?
    var durationMs: Int?
}

struct ChatMessage: Identifiable, Codable, Hashable {
    @DocumentID var messageId: String?
    let senderId: String
    let type: ChatMessageType
    var text: String?
    var media: ChatMessageMedia?
    let createdAt: Timestamp
    var status: String?

    var id: String {
        messageId ?? UUID().uuidString
    }
}

struct UserChatThreadIndex: Identifiable, Codable, Hashable {
    @DocumentID var threadId: String?
    let type: ChatThreadType
    var state: ChatMemberState
    let updatedAt: Timestamp
    var lastMessageText: String?
    var lastMessageType: ChatMessageType?
    var lastMessageSenderId: String?
    var unreadCount: Int?
    var namePreview: String?
    var photoPreview: String?
    var memberIds: [String]

    var id: String {
        threadId ?? UUID().uuidString
    }
}

struct ChatThreadInvite: Identifiable, Codable, Hashable {
    @DocumentID var inviteId: String?
    let toUid: String
    let fromUid: String
    let createdAt: Timestamp
    var status: String

    var id: String {
        inviteId ?? UUID().uuidString
    }
}

struct ChatMemberDetail: Identifiable, Hashable {
    let user: User
    var membership: ChatThreadMember

    var id: String {
        user.id
    }
}
