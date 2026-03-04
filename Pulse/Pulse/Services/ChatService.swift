//
//  ChatService.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore

enum ChatServiceError: LocalizedError {
    case missingAuthenticatedUser
    case blocked
    case chatNotFound
    case membershipNotFound
    case cannotSendInCurrentState
    case invalidDirectMessageTarget
    case groupOnly
    case adminRequired

    var errorDescription: String? {
        switch self {
        case .missingAuthenticatedUser:
            return "You must be signed in to use messages."
        case .blocked:
            return "This conversation is blocked."
        case .chatNotFound:
            return "This chat could not be found."
        case .membershipNotFound:
            return "Your membership data could not be loaded."
        case .cannotSendInCurrentState:
            return "You can't send messages in this chat right now."
        case .invalidDirectMessageTarget:
            return "You can't message this user."
        case .groupOnly:
            return "This action is only available in group chats."
        case .adminRequired:
            return "Only group admins can do that."
        }
    }
}

struct ChatService {
    private static let db = Firestore.firestore()
    private static let chatsCollection = "chats"
    private static let userChatsCollection = "userChats"
    private static let blocksCollection = "blocks"

    static func directMessageThreadId(between uidA: String, and uidB: String) -> String {
        let sorted = [uidA, uidB].sorted()
        return "dm_\(sorted[0])_\(sorted[1])"
    }

    static func fetchThreadIndices() async throws -> [UserChatThreadIndex] {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let snapshot = try await db.collection(userChatsCollection)
            .document(currentUid)
            .collection("chats")
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: UserChatThreadIndex.self) }
    }

    static func fetchThread(threadId: String) async throws -> ChatThread {
        let snapshot = try await db.collection(chatsCollection).document(threadId).getDocument()
        guard snapshot.exists, let thread = try? snapshot.data(as: ChatThread.self) else {
            throw ChatServiceError.chatNotFound
        }

        return thread
    }

    static func fetchMembership(threadId: String, uid: String? = Auth.auth().currentUser?.uid) async throws -> ChatThreadMember {
        guard let uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let snapshot = try await db.collection(chatsCollection)
            .document(threadId)
            .collection("members")
            .document(uid)
            .getDocument()

        guard snapshot.exists, let membership = try? snapshot.data(as: ChatThreadMember.self) else {
            throw ChatServiceError.membershipNotFound
        }

        return membership
    }

    static func fetchMessages(threadId: String) async throws -> [ChatMessage] {
        let snapshot = try await db.collection(chatsCollection)
            .document(threadId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ChatMessage.self) }
    }

    static func listenForMessages(
        threadId: String,
        onUpdate: @escaping ([ChatMessage]) -> Void
    ) -> ListenerRegistration {
        db.collection(chatsCollection)
            .document(threadId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap { try? $0.data(as: ChatMessage.self) } ?? []
                onUpdate(messages)
            }
    }

    static func createOrOpenDirectThread(with user: User) async throws -> ChatThread {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        guard currentUid != user.id else {
            throw ChatServiceError.invalidDirectMessageTarget
        }

        if try await isBlockedBetween(currentUid, user.id) {
            throw ChatServiceError.blocked
        }

        let threadId = directMessageThreadId(between: currentUid, and: user.id)
        let threadRef = db.collection(chatsCollection).document(threadId)
        let existingSnapshot = try await threadRef.getDocument()

        if existingSnapshot.exists, let existingThread = try? existingSnapshot.data(as: ChatThread.self) {
            return existingThread
        }

        let shouldStartAsActive = (try? await FollowService.isUser(user.id, following: currentUid)) ?? false
        let recipientState: ChatMemberState = shouldStartAsActive ? .active : .requested
        let now = Timestamp()

        let thread = ChatThread(
            threadId: threadId,
            type: .dm,
            createdAt: now,
            createdBy: currentUid,
            memberIds: [currentUid, user.id].sorted(),
            title: nil,
            photoURL: nil,
            lastMessageText: nil,
            lastMessageAt: now,
            lastMessageType: nil,
            lastMessageSenderId: nil
        )

        let senderMember = ChatThreadMember(
            memberId: currentUid,
            role: .member,
            joinedAt: now,
            lastReadAt: now,
            mute: false,
            archived: false,
            state: .active,
            requestedBy: nil,
            acceptedAt: now,
            deletedAt: nil
        )

        let recipientMember = ChatThreadMember(
            memberId: user.id,
            role: .member,
            joinedAt: now,
            lastReadAt: nil,
            mute: false,
            archived: false,
            state: recipientState,
            requestedBy: recipientState == .requested ? currentUid : nil,
            acceptedAt: recipientState == .active ? now : nil,
            deletedAt: nil
        )

        let senderIndex = UserChatThreadIndex(
            threadId: threadId,
            type: .dm,
            state: .active,
            updatedAt: now,
            lastMessageText: nil,
            lastMessageType: nil,
            lastMessageSenderId: nil,
            unreadCount: 0,
            namePreview: user.fullname,
            photoPreview: user.profileImageUrl,
            memberIds: [currentUid, user.id].sorted()
        )

        let currentUser = UserService.shared.currentUser
        let recipientIndex = UserChatThreadIndex(
            threadId: threadId,
            type: .dm,
            state: recipientState,
            updatedAt: now,
            lastMessageText: nil,
            lastMessageType: nil,
            lastMessageSenderId: nil,
            unreadCount: 0,
            namePreview: currentUser?.fullname ?? currentUid,
            photoPreview: currentUser?.profileImageUrl,
            memberIds: [currentUid, user.id].sorted()
        )

        let batch = db.batch()
        try encode(thread, to: threadRef, using: batch)
        try encode(senderMember, to: threadRef.collection("members").document(currentUid), using: batch)
        try encode(recipientMember, to: threadRef.collection("members").document(user.id), using: batch)
        try encode(senderIndex, to: db.collection(userChatsCollection).document(currentUid).collection("chats").document(threadId), using: batch)
        try encode(recipientIndex, to: db.collection(userChatsCollection).document(user.id).collection("chats").document(threadId), using: batch)
        try await batch.commit()

        return thread
    }

    static func createGroupThread(title: String, memberIds: [String]) async throws -> ChatThread {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let allMembers = Array(Set(memberIds + [currentUid])).sorted()
        let threadRef = db.collection(chatsCollection).document()
        let threadId = threadRef.documentID
        let now = Timestamp()

        let thread = ChatThread(
            threadId: threadId,
            type: .group,
            createdAt: now,
            createdBy: currentUid,
            memberIds: allMembers,
            title: title,
            photoURL: nil,
            lastMessageText: nil,
            lastMessageAt: now,
            lastMessageType: nil,
            lastMessageSenderId: nil
        )

        let batch = db.batch()
        try encode(thread, to: threadRef, using: batch)

        for uid in allMembers {
            let isCreator = uid == currentUid
            let member = ChatThreadMember(
                memberId: uid,
                role: isCreator ? .admin : .member,
                joinedAt: now,
                lastReadAt: isCreator ? now : nil,
                mute: false,
                archived: false,
                state: .active,
                requestedBy: nil,
                acceptedAt: now,
                deletedAt: nil
            )

            let index = UserChatThreadIndex(
                threadId: threadId,
                type: .group,
                state: .active,
                updatedAt: now,
                lastMessageText: nil,
                lastMessageType: nil,
                lastMessageSenderId: nil,
                unreadCount: 0,
                namePreview: title,
                photoPreview: nil,
                memberIds: allMembers
            )

            try encode(member, to: threadRef.collection("members").document(uid), using: batch)
            try encode(index, to: db.collection(userChatsCollection).document(uid).collection("chats").document(threadId), using: batch)
        }

        try await batch.commit()
        return thread
    }

    static func sendMessage(threadId: String, text: String) async throws {
        try await sendMessage(
            threadId: threadId,
            text: text,
            type: .text,
            media: nil
        )
    }

    static func sendMediaMessage(
        threadId: String,
        text: String? = nil,
        type: ChatMessageType,
        media: ChatMessageMedia
    ) async throws {
        try await sendMessage(
            threadId: threadId,
            text: text,
            type: type,
            media: media
        )
    }

    static func fetchMemberDetails(threadId: String) async throws -> [ChatMemberDetail] {
        let thread = try await fetchThread(threadId: threadId)
        let memberships = try await fetchMemberships(threadId: threadId)
        var details = [ChatMemberDetail]()

        for memberId in thread.memberIds {
            guard let membership = memberships[memberId],
                  membership.deletedAt == nil,
                  let user = try await UserService.fetchUser(withUid: memberId) else { continue }

            details.append(ChatMemberDetail(user: user, membership: membership))
        }

        return details.sorted { lhs, rhs in
            if lhs.membership.role != rhs.membership.role {
                return lhs.membership.role == .admin
            }

            if lhs.membership.state != rhs.membership.state {
                return lhs.membership.state.rawValue < rhs.membership.state.rawValue
            }

            return lhs.user.fullname.localizedCaseInsensitiveCompare(rhs.user.fullname) == .orderedAscending
        }
    }

    static func inviteUsers(toGroup threadId: String, userIds: [String]) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let thread = try await fetchThread(threadId: threadId)
        guard thread.type == .group else {
            throw ChatServiceError.groupOnly
        }

        let memberships = try await fetchMemberships(threadId: threadId)
        guard let currentMembership = memberships[currentUid] else {
            throw ChatServiceError.membershipNotFound
        }

        guard currentMembership.role == .admin, currentMembership.state == .active else {
            throw ChatServiceError.adminRequired
        }

        let now = Timestamp()
        var updatedThread = thread
        var updatedMemberIds = Set(thread.memberIds)
        let batch = db.batch()

        for uid in Set(userIds) where uid != currentUid {
            if let existing = memberships[uid], existing.deletedAt == nil, !existing.archived {
                continue
            }

            updatedMemberIds.insert(uid)

            let membership = ChatThreadMember(
                memberId: uid,
                role: .member,
                joinedAt: now,
                lastReadAt: nil,
                mute: false,
                archived: false,
                state: .requested,
                requestedBy: currentUid,
                acceptedAt: nil,
                deletedAt: nil
            )

            let inviteRef = db.collection(chatsCollection)
                .document(threadId)
                .collection("invites")
                .document()

            let invite = ChatThreadInvite(
                inviteId: inviteRef.documentID,
                toUid: uid,
                fromUid: currentUid,
                createdAt: now,
                status: "pending"
            )

            let index = UserChatThreadIndex(
                threadId: threadId,
                type: .group,
                state: .requested,
                updatedAt: updatedThread.lastMessageAt ?? now,
                lastMessageText: updatedThread.lastMessageText,
                lastMessageType: updatedThread.lastMessageType,
                lastMessageSenderId: updatedThread.lastMessageSenderId,
                unreadCount: 0,
                namePreview: updatedThread.title ?? "Group",
                photoPreview: updatedThread.photoURL,
                memberIds: Array(updatedMemberIds).sorted()
            )

            try encode(membership, to: db.collection(chatsCollection).document(threadId).collection("members").document(uid), using: batch)
            try encode(invite, to: inviteRef, using: batch)
            try encode(index, to: db.collection(userChatsCollection).document(uid).collection("chats").document(threadId), using: batch)
        }

        updatedThread.memberIds = Array(updatedMemberIds).sorted()
        try encode(updatedThread, to: db.collection(chatsCollection).document(threadId), using: batch)
        try await batch.commit()
    }

    static func updateMemberRole(
        threadId: String,
        memberId: String,
        role: ChatMemberRole
    ) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let thread = try await fetchThread(threadId: threadId)
        guard thread.type == .group else {
            throw ChatServiceError.groupOnly
        }

        let currentMembership = try await fetchMembership(threadId: threadId, uid: currentUid)
        guard currentMembership.role == .admin, currentMembership.state == .active else {
            throw ChatServiceError.adminRequired
        }

        try await db.collection(chatsCollection)
            .document(threadId)
            .collection("members")
            .document(memberId)
            .setData(["role": role.rawValue], merge: true)
    }

    static func removeMember(
        fromGroup threadId: String,
        memberId: String
    ) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let thread = try await fetchThread(threadId: threadId)
        guard thread.type == .group else {
            throw ChatServiceError.groupOnly
        }

        let currentMembership = try await fetchMembership(threadId: threadId, uid: currentUid)
        guard currentMembership.role == .admin, currentMembership.state == .active else {
            throw ChatServiceError.adminRequired
        }

        let now = Timestamp()
        let updatedMemberIds = thread.memberIds.filter { $0 != memberId }

        let batch = db.batch()
        batch.updateData(["memberIds": updatedMemberIds], forDocument: db.collection(chatsCollection).document(threadId))
        batch.setData([
            "archived": true,
            "deletedAt": now
        ], forDocument: db.collection(chatsCollection).document(threadId).collection("members").document(memberId), merge: true)
        batch.deleteDocument(db.collection(userChatsCollection).document(memberId).collection("chats").document(threadId))
        try await batch.commit()
    }

    static func sendMessage(
        threadId: String,
        text: String?,
        type: ChatMessageType,
        media: ChatMessageMedia?
    ) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let trimmedText = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedText.isEmpty || media != nil else { return }

        let thread = try await fetchThread(threadId: threadId)
        let memberships = try await fetchMemberships(threadId: threadId)

        guard let currentMembership = memberships[currentUid] else {
            throw ChatServiceError.membershipNotFound
        }

        guard currentMembership.state == .active else {
            throw ChatServiceError.cannotSendInCurrentState
        }

        let now = Timestamp()
        let messageRef = db.collection(chatsCollection)
            .document(threadId)
            .collection("messages")
            .document()

        let message = ChatMessage(
            messageId: messageRef.documentID,
            senderId: currentUid,
            type: type,
            text: trimmedText.isEmpty ? nil : trimmedText,
            media: media,
            createdAt: now,
            status: "sent"
        )

        let previewText = lastMessagePreview(for: type, text: trimmedText)
        var updatedThread = thread
        updatedThread.lastMessageText = previewText
        updatedThread.lastMessageAt = now
        updatedThread.lastMessageType = type
        updatedThread.lastMessageSenderId = currentUid

        let batch = db.batch()
        try encode(message, to: messageRef, using: batch)
        try encode(updatedThread, to: db.collection(chatsCollection).document(threadId), using: batch)

        for memberId in thread.memberIds {
            guard let member = memberships[memberId] else { continue }

            let memberRef = db.collection(chatsCollection)
                .document(threadId)
                .collection("members")
                .document(memberId)

            let indexRef = db.collection(userChatsCollection)
                .document(memberId)
                .collection("chats")
                .document(threadId)

            if member.state == .blocked || member.archived || member.deletedAt != nil {
                continue
            }

            var updates: [String: Any] = [
                "updatedAt": now,
                "lastMessageText": previewText,
                "lastMessageType": type.rawValue,
                "lastMessageSenderId": currentUid,
                "state": member.state.rawValue,
                "type": thread.type.rawValue,
                "memberIds": thread.memberIds
            ]

            if thread.type == .group {
                updates["namePreview"] = thread.title ?? "Group"
                updates["photoPreview"] = thread.photoURL ?? ""
            } else {
                updates["namePreview"] = FieldValue.delete()
                updates["photoPreview"] = FieldValue.delete()
            }

            if memberId == currentUid {
                updates["unreadCount"] = 0
                batch.updateData(["lastReadAt": now], forDocument: memberRef)
            } else {
                updates["unreadCount"] = FieldValue.increment(Int64(1))
            }

            batch.setData(updates, forDocument: indexRef, merge: true)
        }

        try await batch.commit()
    }

    static func markThreadRead(threadId: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let now = Timestamp()

        async let memberTask: Void = db.collection(chatsCollection)
            .document(threadId)
            .collection("members")
            .document(currentUid)
            .setData(["lastReadAt": now], merge: true)

        async let indexTask: Void = db.collection(userChatsCollection)
            .document(currentUid)
            .collection("chats")
            .document(threadId)
            .setData(["unreadCount": 0], merge: true)

        _ = try await (memberTask, indexTask)
    }

    static func acceptRequest(threadId: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let now = Timestamp()
        let memberRef = db.collection(chatsCollection)
            .document(threadId)
            .collection("members")
            .document(currentUid)

        try await memberRef.setData([
            "state": ChatMemberState.active.rawValue,
            "acceptedAt": now,
            "requestedBy": FieldValue.delete(),
            "archived": false,
            "deletedAt": FieldValue.delete()
        ], merge: true)

        try await db.collection(userChatsCollection)
            .document(currentUid)
            .collection("chats")
            .document(threadId)
            .setData([
                "state": ChatMemberState.active.rawValue,
                "updatedAt": now
            ], merge: true)
    }

    static func deleteRequest(threadId: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let now = Timestamp()
        let memberRef = db.collection(chatsCollection)
            .document(threadId)
            .collection("members")
            .document(currentUid)

        try await memberRef.setData([
            "archived": true,
            "deletedAt": now
        ], merge: true)

        try await db.collection(userChatsCollection)
            .document(currentUid)
            .collection("chats")
            .document(threadId)
            .delete()
    }

    static func blockThread(threadId: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ChatServiceError.missingAuthenticatedUser
        }

        let thread = try await fetchThread(threadId: threadId)

        try await db.collection(chatsCollection)
            .document(threadId)
            .collection("members")
            .document(currentUid)
            .setData(["state": ChatMemberState.blocked.rawValue], merge: true)

        try await db.collection(userChatsCollection)
            .document(currentUid)
            .collection("chats")
            .document(threadId)
            .delete()

        if thread.type == .dm, let otherUid = thread.memberIds.first(where: { $0 != currentUid }) {
            try await db.collection(blocksCollection)
                .document(currentUid)
                .collection("blocked")
                .document(otherUid)
                .setData(["createdAt": Timestamp()])
        }
    }

    private static func isBlockedBetween(_ currentUid: String, _ otherUid: String) async throws -> Bool {
        async let currentBlocked = db.collection(blocksCollection)
            .document(currentUid)
            .collection("blocked")
            .document(otherUid)
            .getDocument()

        async let otherBlocked = db.collection(blocksCollection)
            .document(otherUid)
            .collection("blocked")
            .document(currentUid)
            .getDocument()

        let currentSnapshot = try await currentBlocked
        let otherSnapshot = try await otherBlocked
        return currentSnapshot.exists || otherSnapshot.exists
    }

    private static func lastMessagePreview(for type: ChatMessageType, text: String) -> String {
        if !text.isEmpty {
            return text
        }

        switch type {
        case .text:
            return "New message"
        case .image:
            return "Sent a photo"
        case .file:
            return "Sent a file"
        case .audio:
            return "Sent an audio clip"
        }
    }

    private static func fetchMemberships(threadId: String) async throws -> [String: ChatThreadMember] {
        let snapshot = try await db.collection(chatsCollection)
            .document(threadId)
            .collection("members")
            .getDocuments()

        return snapshot.documents.reduce(into: [:]) { result, document in
            if let membership = try? document.data(as: ChatThreadMember.self) {
                result[document.documentID] = membership
            }
        }
    }

    private static func encode<T: Encodable>(
        _ value: T,
        to document: DocumentReference,
        using batch: WriteBatch
    ) throws {
        let data = try Firestore.Encoder().encode(value)
        batch.setData(data, forDocument: document)
    }
}
