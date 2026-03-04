//
//  ChatThreadView.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import FirebaseAuth
import PhotosUI
import SwiftUI

struct ChatThreadView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatThreadViewModel

    init(
        threadId: String,
        threadSeed: ChatThread? = nil,
        preferredTitle: String? = nil,
        preferredPhotoURL: String? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: ChatThreadViewModel(
                threadId: threadId,
                threadSeed: threadSeed,
                preferredTitle: preferredTitle,
                preferredPhotoURL: preferredPhotoURL
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isRequest {
                requestBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    threadHeader

                    if viewModel.messages.isEmpty {
                        AppEmptyStateCard(
                            systemImage: "ellipsis.message",
                            title: "No Messages Yet",
                            message: viewModel.isRequest
                                ? "Review this request or accept it to start replying."
                                : "Start the conversation."
                        ) {
                            EmptyView()
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                messageBubble(for: message)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider()

            composerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let subtitle = viewModel.subtitleText {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(viewModel.titleText)
                            .font(.headline)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if viewModel.thread?.type == .group {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        GroupMembersView(threadId: viewModel.threadId)
                    } label: {
                        Image(systemName: "person.3")
                    }
                    .accessibilityIdentifier("chatThread.members")
                }
            }
        }
        .accessibilityIdentifier("chatThread.view")
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert("Couldn't Update Chat", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var threadHeader: some View {
        HStack(spacing: 12) {
            CircularProfileImageView(
                user: viewModel.peerUser,
                imageUrl: viewModel.peerImageURL,
                size: .medium
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.titleText)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle = viewModel.subtitleText {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var requestBanner: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.requestBannerText)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Accept to reply, delete to remove it from your requests, or block to stop future messages from this user.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button {
                        Task { await viewModel.acceptRequest() }
                    } label: {
                        Text(viewModel.isGroupInvite ? "Join" : "Accept")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppPrimaryButtonStyle())

                    Button {
                        Task {
                            if await viewModel.deleteRequest() {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Delete")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppSecondaryButtonStyle())

                    if !viewModel.isGroupInvite {
                        Button {
                            Task {
                                if await viewModel.blockThread() {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("Block")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppDestructiveButtonStyle())
                    }
                }
            }
        }
    }

    private var composerBar: some View {
        Group {
            if viewModel.isBlocked {
                statusBar(
                    text: "This chat is blocked. You can still review earlier messages."
                )
            } else if viewModel.isRequest {
                statusBar(
                    text: viewModel.isGroupInvite ? "Join this group to reply." : "Accept this request to reply."
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    if let selectedImage = viewModel.selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    viewModel.removeImageAttachment()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .padding(8)
                                }
                            }
                    } else if viewModel.isRecordingVoice || viewModel.hasVoiceAttachment {
                        HStack(spacing: 10) {
                            Image(systemName: viewModel.isRecordingVoice ? "record.circle.fill" : "waveform")
                                .foregroundStyle(viewModel.isRecordingVoice ? .red : .primary)

                            Text(viewModel.isRecordingVoice ? "Recording audio..." : "Audio clip attached")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button(viewModel.isRecordingVoice ? "Stop" : "Remove") {
                                if viewModel.isRecordingVoice {
                                    Task { await viewModel.toggleVoiceRecording() }
                                } else {
                                    viewModel.removeVoiceAttachment()
                                }
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }

                    HStack(alignment: .bottom, spacing: 12) {
                        PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                            Image(systemName: "photo")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("chatThread.photo")

                        Button {
                            Task { await viewModel.toggleVoiceRecording() }
                        } label: {
                            Image(systemName: viewModel.isRecordingVoice ? "stop.circle" : "mic")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("chatThread.voice")

                        TextField("Write a message", text: $viewModel.composerText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(1...4)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: AppUI.cardCornerRadius, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .accessibilityIdentifier("chatThread.input")

                        Button {
                            Task { await viewModel.sendMessage() }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                        }
                        .foregroundStyle(canSubmit ? .primary : .secondary)
                        .disabled(!canSubmit || viewModel.isSending)
                        .accessibilityIdentifier("chatThread.send")
                    }
                }
            }
        }
    }

    private func statusBar(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppUI.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }

    private func messageBubble(for message: ChatMessage) -> some View {
        let isCurrentUser = message.senderId == Auth.auth().currentUser?.uid

        return HStack {
            if isCurrentUser {
                Spacer(minLength: 48)
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                mediaContent(for: message, isCurrentUser: isCurrentUser)

                Text(message.createdAt.timestampString())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !isCurrentUser {
                Spacer(minLength: 48)
            }
        }
    }

    private func messageLabel(for message: ChatMessage) -> String {
        if let text = message.text, !text.isEmpty {
            return text
        }

        switch message.type {
        case .text:
            return "Message"
        case .image:
            return "Image attachment"
        case .file:
            return "File attachment"
        case .audio:
            return "Audio clip"
        }
    }

    private var canSubmit: Bool {
        !viewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || viewModel.selectedImage != nil
        || viewModel.isRecordingVoice
        || viewModel.hasVoiceAttachment
    }

    @ViewBuilder
    private func mediaContent(for message: ChatMessage, isCurrentUser: Bool) -> some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 8) {
            switch message.type {
            case .image:
                if let urlString = message.media?.url, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholderBubble(text: "Photo unavailable", isCurrentUser: isCurrentUser)
                        case .empty:
                            ProgressView()
                                .frame(width: 180, height: 180)
                        @unknown default:
                            placeholderBubble(text: "Photo unavailable", isCurrentUser: isCurrentUser)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            case .audio:
                if let urlString = message.media?.url {
                    VoiceClipPlayerView(
                        audioUrl: urlString,
                        duration: message.media?.durationMs.map { Double($0) / 1000 }
                    )
                    .frame(maxWidth: 220, alignment: isCurrentUser ? .trailing : .leading)
                }
            case .file, .text:
                EmptyView()
            }

            if let text = message.text, !text.isEmpty || message.type == .text {
                Text(messageLabel(for: message))
                    .font(.body)
                    .foregroundStyle(isCurrentUser ? Color(.systemBackground) : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isCurrentUser ? Color.primary : Color(.secondarySystemBackground))
                    )
            }
        }
    }

    private func placeholderBubble(text: String, isCurrentUser: Bool) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(isCurrentUser ? Color(.systemBackground) : .secondary)
            .frame(width: 180, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isCurrentUser ? Color.primary.opacity(0.8) : Color(.secondarySystemBackground))
            )
    }
}

#Preview {
    NavigationStack {
        ChatThreadView(threadId: "preview-chat")
    }
}
