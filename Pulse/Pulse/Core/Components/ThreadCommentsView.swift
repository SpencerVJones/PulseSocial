//
//  ThreadCommentsView.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import SwiftUI

struct ThreadCommentsView: View {
    @StateObject private var viewModel: ThreadCommentsViewModel
    let onCommentCountChanged: (Int) -> Void

    init(thread: Thread, onCommentCountChanged: @escaping (Int) -> Void) {
        self._viewModel = StateObject(wrappedValue: ThreadCommentsViewModel(thread: thread))
        self.onCommentCountChanged = onCommentCountChanged
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.comments.isEmpty {
                    ContentUnavailableView(
                        "No Comments Yet",
                        systemImage: "bubble.right",
                        description: Text("Start the conversation.")
                    )
                } else {
                    List(viewModel.comments) { comment in
                        HStack(alignment: .top, spacing: 10) {
                            CircularProfileImageView(
                                user: comment.user,
                                imageUrl: comment.ownerProfileImageUrl,
                                size: .xSmall
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(comment.user?.username ?? comment.ownerUsername ?? "Anonymous")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    if comment.isPendingSync {
                                        Text("Pending")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .foregroundStyle(.orange)
                                            .clipShape(Capsule())
                                    }
                                }

                                if !comment.commentText.isEmpty {
                                    Text(comment.commentText)
                                        .font(.footnote)
                                        .foregroundStyle(.primary)
                                }

                                if let voiceClipUrl = comment.voiceClipUrl {
                                    VoiceClipPlayerView(
                                        audioUrl: voiceClipUrl,
                                        duration: comment.voiceClipDuration
                                    )
                                }
                            }

                            Spacer()

                            Text(comment.timestamp.timestampString())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Write a comment...", text: $viewModel.commentText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)

                    Button {
                        Task { await viewModel.toggleVoiceRecording() }
                    } label: {
                        Image(systemName: viewModel.isRecordingVoice ? "stop.circle.fill" : "mic.circle")
                            .font(.title3)
                            .foregroundStyle(viewModel.isRecordingVoice ? .red : .primary)
                    }
                    .buttonStyle(.plain)

                    Button("Send") {
                        Task {
                            await viewModel.postComment()
                            onCommentCountChanged(viewModel.comments.count)
                        }
                    }
                    .disabled(
                        viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && !viewModel.hasVoiceAttachment
                        && !viewModel.isRecordingVoice
                    )
                    .fontWeight(.semibold)
                }
                .padding()

                if viewModel.isRecordingVoice {
                    HStack(spacing: 8) {
                        Image(systemName: "record.circle.fill")
                            .foregroundStyle(.red)
                        Text("Recording voice reply...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                } else if viewModel.hasVoiceAttachment {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Voice reply attached")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Remove") {
                            viewModel.removeVoiceAttachment()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.fetchComments()
            onCommentCountChanged(viewModel.comments.count)
        }
    }
}

#Preview {
    ThreadCommentsView(thread: DeveloperPreview.shared.thread) { _ in }
}
