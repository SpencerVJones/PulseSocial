//  CreateThreadViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/13/25

import FirebaseAuth
import Firebase
import PhotosUI
import SwiftUI
import UIKit

enum CreateThreadError: LocalizedError {
    case missingAuthenticatedUser
    case emptyThreadContent

    var errorDescription: String? {
        switch self {
        case .missingAuthenticatedUser:
            return "You must be logged in to post."
        case .emptyThreadContent:
            return "Add text or an image before posting."
        }
    }
}

@MainActor
class CreateThreadViewModel: ObservableObject {
    @Published var caption = ""
    @Published var isUploading = false
    @Published var showUploadError = false
    @Published var uploadErrorMessage = ""
    @Published var circles = [Circle]()
    @Published var selectedCircle = CircleService.defaultCircle
    @Published var dailyPrompt = PromptService.dailyPrompt()
    @Published var attachPrompt = true
    @Published var isRecordingVoice = false
    @Published var voiceAttachmentDuration: TimeInterval?
    @Published var hasVoiceAttachment = false
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadImage() } }
    }
    @Published var selectedImage: Image?

    private var uiImage: UIImage?
    private let voiceRecorder = VoiceRecorderService()

    init() {
        Task {
            circles = await CircleService.fetchCircles()
            if let first = circles.first {
                selectedCircle = first
            }
        }
    }
    
    func submitThread() async -> Bool {
        isUploading = true
        defer { isUploading = false }

        do {
            try await uploadThread()
            return true
        } catch {
            uploadErrorMessage = error.localizedDescription
            showUploadError = true
            return false
        }
    }

    private func uploadThread() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw CreateThreadError.missingAuthenticatedUser
        }

        if isRecordingVoice {
            stopVoiceRecording()
        }

        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCaption.isEmpty || uiImage != nil || hasVoiceAttachment else {
            throw CreateThreadError.emptyThreadContent
        }

        let imageUrl: String?
        if let uiImage {
            imageUrl = try await ImageUploader.uploadThreadImage(uiImage)
        } else {
            imageUrl = nil
        }

        let voiceClipUrl: String?
        if let recordingURL = voiceRecorder.recordingURL {
            voiceClipUrl = try await ImageUploader.uploadThreadVoiceClip(from: recordingURL)
        } else {
            voiceClipUrl = nil
        }

        let prompt = attachPrompt ? dailyPrompt : nil

        let thread = Thread(
            ownerUid: uid,
            operationId: UUID().uuidString,
            caption: trimmedCaption,
            timestamp: Timestamp(),
            likes: 0,
            ownerUsername: UserService.shared.currentUser?.username,
            ownerProfileImageUrl: UserService.shared.currentUser?.profileImageUrl,
            circleId: selectedCircle.id,
            circleName: selectedCircle.name,
            promptId: prompt?.id,
            promptTitle: prompt?.title,
            voiceClipUrl: voiceClipUrl,
            voiceClipDuration: voiceAttachmentDuration,
            isRepost: false,
            reactionCounts: [:],
            currentUserReaction: nil,
            imageUrl: imageUrl,
            commentCount: 0
        )

        try await ThreadService.uploadThread(thread)
        NotificationCenter.default.post(name: .postDidPublish, object: nil)
        clearComposer()
    }

    private func clearComposer() {
        caption = ""
        clearAttachment()
        removeVoiceAttachment()
    }

    func clearAttachment() {
        selectedItem = nil
        selectedImage = nil
        uiImage = nil
    }

    func toggleVoiceRecording() async {
        if isRecordingVoice {
            stopVoiceRecording()
            return
        }

        do {
            try await voiceRecorder.startRecording(maxDuration: 45)
            isRecordingVoice = true
            hasVoiceAttachment = false
            voiceAttachmentDuration = nil
        } catch {
            uploadErrorMessage = error.localizedDescription
            showUploadError = true
        }
    }

    func removeVoiceAttachment() {
        voiceRecorder.clearRecording()
        hasVoiceAttachment = false
        voiceAttachmentDuration = nil
        isRecordingVoice = false
    }

    private func loadImage() async {
        guard let item = selectedItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }

        self.uiImage = uiImage
        self.selectedImage = Image(uiImage: uiImage)
    }

    private func stopVoiceRecording() {
        _ = voiceRecorder.stopRecording()
        isRecordingVoice = false
        hasVoiceAttachment = voiceRecorder.recordingURL != nil
        voiceAttachmentDuration = voiceRecorder.recordingDuration
    }
}
