//
//  ThreadCommentsViewModel.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import Foundation

@MainActor
final class ThreadCommentsViewModel: ObservableObject {
    @Published var comments = [ThreadComment]()
    @Published var commentText = ""
    @Published var isRecordingVoice = false
    @Published var voiceAttachmentDuration: TimeInterval?
    @Published var hasVoiceAttachment = false

    let thread: Thread
    private let voiceRecorder = VoiceRecorderService()

    init(thread: Thread) {
        self.thread = thread
    }

    func fetchComments() async {
        do {
            comments = try await CommentService.fetchComments(for: thread)
        } catch {
            print("DEBUG: Failed to fetch comments: \(error.localizedDescription)")
        }
    }

    func postComment() async {
        do {
            if isRecordingVoice {
                stopVoiceRecording()
            }

            try await CommentService.addComment(
                to: thread,
                text: commentText,
                voiceClipFileURL: voiceRecorder.recordingURL,
                voiceClipDuration: voiceAttachmentDuration
            )
            commentText = ""
            clearVoiceAttachment()
            await fetchComments()
            NotificationCenter.default.post(name: .commentDidPost, object: nil)
        } catch {
            print("DEBUG: Failed to post comment: \(error.localizedDescription)")
        }
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
            print("DEBUG: Failed to start comment recording: \(error.localizedDescription)")
        }
    }

    func removeVoiceAttachment() {
        clearVoiceAttachment()
    }

    private func stopVoiceRecording() {
        _ = voiceRecorder.stopRecording()
        isRecordingVoice = false
        hasVoiceAttachment = voiceRecorder.recordingURL != nil
        voiceAttachmentDuration = voiceRecorder.recordingDuration
    }

    private func clearVoiceAttachment() {
        voiceRecorder.clearRecording()
        hasVoiceAttachment = false
        voiceAttachmentDuration = nil
        isRecordingVoice = false
    }
}
