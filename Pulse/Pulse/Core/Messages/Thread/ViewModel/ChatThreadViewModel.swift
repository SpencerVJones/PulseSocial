//
//  ChatThreadViewModel.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ChatThreadViewModel: ObservableObject {
    @Published var thread: ChatThread?
    @Published var membership: ChatThreadMember?
    @Published var messages = [ChatMessage]()
    @Published var peerUser: User?
    @Published var composerText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadImage() } }
    }
    @Published var selectedImage: Image?
    @Published var isRecordingVoice = false
    @Published var voiceAttachmentDuration: TimeInterval?
    @Published var hasVoiceAttachment = false

    let threadId: String
    private let preferredTitle: String?
    private let preferredPhotoURL: String?
    private var messageListener: ListenerRegistration?
    private let voiceRecorder = VoiceRecorderService()
    private var selectedUIImage: UIImage?

    init(
        threadId: String,
        threadSeed: ChatThread? = nil,
        preferredTitle: String? = nil,
        preferredPhotoURL: String? = nil
    ) {
        self.threadId = threadId
        self.thread = threadSeed
        self.preferredTitle = preferredTitle
        self.preferredPhotoURL = preferredPhotoURL
    }

    deinit {
        messageListener?.remove()
    }

    var titleText: String {
        if thread?.type == .group {
            return thread?.title ?? "Group"
        }

        return peerUser?.fullname ?? preferredTitle ?? "Messages"
    }

    var subtitleText: String? {
        if thread?.type == .group {
            let memberCount = thread?.memberIds.count ?? 0
            return memberCount == 1 ? "1 member" : "\(memberCount) members"
        }

        return peerUser.map { "@\($0.username)" }
    }

    var peerImageURL: String? {
        peerUser?.profileImageUrl ?? preferredPhotoURL
    }

    var isRequest: Bool {
        membership?.state == .requested
    }

    var isGroupInvite: Bool {
        thread?.type == .group && isRequest
    }

    var isBlocked: Bool {
        membership?.state == .blocked
    }

    var requestBannerText: String {
        if isGroupInvite {
            return "Group invite to \(thread?.title ?? "this group")"
        }

        if let peerUser {
            return "Message request from @\(peerUser.username)"
        }

        return "Message request"
    }

    func loadIfNeeded() async {
        guard thread == nil || messages.isEmpty || membership == nil else {
            startListening()
            return
        }

        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedThread = try await ChatService.fetchThread(threadId: threadId)
            let loadedMembership = try await ChatService.fetchMembership(threadId: threadId)
            let loadedMessages = try await ChatService.fetchMessages(threadId: threadId)

            thread = loadedThread
            membership = loadedMembership
            messages = loadedMessages

            await loadPeerUserIfNeeded(for: loadedThread)
            startListening()
            try await ChatService.markThreadRead(threadId: threadId)
        } catch {
            presentError(error)
        }
    }

    func sendMessage() async {
        guard !isSending else { return }

        if isRecordingVoice {
            stopVoiceRecording()
        }

        let trimmedText = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || selectedUIImage != nil || hasVoiceAttachment else { return }

        isSending = true
        defer { isSending = false }

        do {
            if let selectedUIImage {
                let imageUrl = try await ImageUploader.uploadChatImage(selectedUIImage)
                let media = ChatMessageMedia(
                    url: imageUrl,
                    thumbUrl: nil,
                    fileName: nil,
                    mimeType: "image/jpeg",
                    sizeBytes: nil,
                    durationMs: nil
                )

                try await ChatService.sendMediaMessage(
                    threadId: threadId,
                    text: trimmedText.isEmpty ? nil : trimmedText,
                    type: .image,
                    media: media
                )
            } else if let recordingURL = voiceRecorder.recordingURL {
                let audioUrl = try await ImageUploader.uploadChatAudio(from: recordingURL)
                let media = ChatMessageMedia(
                    url: audioUrl,
                    thumbUrl: nil,
                    fileName: recordingURL.lastPathComponent,
                    mimeType: "audio/m4a",
                    sizeBytes: nil,
                    durationMs: voiceAttachmentDuration.map { Int(($0 * 1000).rounded()) }
                )

                try await ChatService.sendMediaMessage(
                    threadId: threadId,
                    text: trimmedText.isEmpty ? nil : trimmedText,
                    type: .audio,
                    media: media
                )
            } else {
                try await ChatService.sendMessage(threadId: threadId, text: trimmedText)
            }

            clearComposer()
        } catch {
            presentError(error)
        }
    }

    func acceptRequest() async {
        do {
            try await ChatService.acceptRequest(threadId: threadId)
            membership?.state = .active
            membership?.acceptedAt = Timestamp()
        } catch {
            presentError(error)
        }
    }

    func deleteRequest() async -> Bool {
        do {
            try await ChatService.deleteRequest(threadId: threadId)
            return true
        } catch {
            presentError(error)
            return false
        }
    }

    func blockThread() async -> Bool {
        do {
            try await ChatService.blockThread(threadId: threadId)
            membership?.state = .blocked
            return true
        } catch {
            presentError(error)
            return false
        }
    }

    func toggleVoiceRecording() async {
        if isRecordingVoice {
            stopVoiceRecording()
            return
        }

        do {
            removeImageAttachment()
            try await voiceRecorder.startRecording(maxDuration: 45)
            isRecordingVoice = true
            hasVoiceAttachment = false
            voiceAttachmentDuration = nil
        } catch {
            presentError(error)
        }
    }

    func removeImageAttachment() {
        selectedItem = nil
        selectedImage = nil
        selectedUIImage = nil
    }

    func removeVoiceAttachment() {
        voiceRecorder.clearRecording()
        hasVoiceAttachment = false
        isRecordingVoice = false
        voiceAttachmentDuration = nil
    }

    private func startListening() {
        messageListener?.remove()
        messageListener = ChatService.listenForMessages(threadId: threadId) { [weak self] messages in
            Task { @MainActor in
                guard let self else { return }
                self.messages = messages

                do {
                    try await ChatService.markThreadRead(threadId: self.threadId)
                } catch {
                    self.presentError(error)
                }
            }
        }
    }

    private func loadPeerUserIfNeeded(for thread: ChatThread) async {
        guard thread.type == .dm,
              let currentUid = Auth.auth().currentUser?.uid,
              let peerUid = thread.memberIds.first(where: { $0 != currentUid }) else { return }

        do {
            peerUser = try await UserService.fetchUser(withUid: peerUid)
        } catch {
            presentError(error)
        }
    }

    private func loadImage() async {
        guard let item = selectedItem else {
            selectedImage = nil
            selectedUIImage = nil
            return
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        removeVoiceAttachment()
        selectedUIImage = uiImage
        selectedImage = Image(uiImage: uiImage)
    }

    private func stopVoiceRecording() {
        _ = voiceRecorder.stopRecording()
        isRecordingVoice = false
        hasVoiceAttachment = voiceRecorder.recordingURL != nil
        voiceAttachmentDuration = voiceRecorder.recordingDuration
    }

    private func clearComposer() {
        composerText = ""
        removeImageAttachment()
        removeVoiceAttachment()
    }

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
