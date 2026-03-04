//  CreateThreadView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import PhotosUI
import SwiftUI

struct CreateThreadView: View {
    @StateObject var viewModel = CreateThreadViewModel()
    @Environment(\.dismiss) var dismiss

    private let maxCaptionCount = 280

    private var user: User? {
        UserService.shared.currentUser
    }

    private var hasSelectedImage: Bool {
        viewModel.selectedImage != nil
    }

    private var hasVoiceAttachment: Bool {
        viewModel.hasVoiceAttachment
    }

    private var hasContent: Bool {
        !viewModel.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || hasSelectedImage
        || hasVoiceAttachment
        || viewModel.isRecordingVoice
    }

    var body: some View {
        NavigationStack {
            ZStack {
                composerBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        VStack(spacing: 0) {
                            composerHeader
                            dividerLine
                            destinationRow
                            dividerLine
                            composerBody
                        }
                        .background(shellBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .accessibilityIdentifier("createThread.view")
        .onChange(of: viewModel.caption) { _, newValue in
            guard newValue.count > maxCaptionCount else { return }
            viewModel.caption = String(newValue.prefix(maxCaptionCount))
        }
        .alert("Couldn't Publish Post", isPresented: $viewModel.showUploadError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.uploadErrorMessage)
        }
    }

    private var composerBackground: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.03, green: 0.04, blue: 0.08),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var shellBackground: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color(red: 0.06, green: 0.07, blue: 0.11),
                Color.black.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var composerHeader: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.title3)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.92))

            Spacer()

            Text("Create Post")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Spacer()

            Button("Post") {
                Task {
                    let didUpload = await viewModel.submitThread()
                    if didUpload {
                        dismiss()
                    }
                }
            }
            .disabled(!hasContent || viewModel.isUploading)
            .opacity(hasContent ? 1 : 0.5)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .accessibilityIdentifier("createThread.submit")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }

    private var destinationRow: some View {
        Menu {
            ForEach(viewModel.circles) { circle in
                Button {
                    viewModel.selectedCircle = circle
                } label: {
                    Label(circle.name, systemImage: circle.symbol)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("Post to:")
                    .foregroundStyle(.white.opacity(0.65))

                Image(systemName: viewModel.selectedCircle.symbol)
                    .foregroundStyle(.white.opacity(0.92))

                Text(viewModel.selectedCircle.name)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()
            }
            .font(.title3)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    private var composerBody: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                CircularProfileImageView(user: user, size: .medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.fullname ?? "Your profile")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("@\(user?.username ?? "username")")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                if hasContent {
                    Button {
                        viewModel.caption = ""
                        viewModel.clearAttachment()
                        viewModel.removeVoiceAttachment()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }

            captionBox

            if let selectedImage = viewModel.selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            promptRow

            attachmentRow

            if viewModel.isRecordingVoice {
                statusPill(
                    systemImage: "record.circle.fill",
                    text: "Recording voice clip..."
                )
                .foregroundStyle(.red)
            } else if hasVoiceAttachment {
                HStack(spacing: 10) {
                    statusPill(
                        systemImage: "waveform",
                        text: "Voice clip attached \(voiceDurationText)"
                    )

                    Button("Remove") {
                        viewModel.removeVoiceAttachment()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(18)
    }

    private var captionBox: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))

            if viewModel.caption.isEmpty {
                Text("Share your thoughts...")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $viewModel.caption)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .foregroundColor(.white)
                .font(.system(size: 22))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minHeight: 180)
                .accessibilityIdentifier("createThread.caption")

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(viewModel.caption.count)/\(maxCaptionCount)")
                        .font(.title3)
                        .foregroundStyle(viewModel.caption.count >= maxCaptionCount ? .red : .white.opacity(0.5))
                        .padding(.trailing, 16)
                        .padding(.bottom, 14)
                }
            }
        }
        .frame(minHeight: 180)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var promptRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.82))

            HStack(spacing: 6) {
                Text("Daily Prompt")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("·")
                    .foregroundStyle(.white.opacity(0.35))

                Text(viewModel.dailyPrompt.title)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: $viewModel.attachPrompt)
                .labelsHidden()
                .tint(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(tileBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private var attachmentRow: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                attachmentTile(systemImage: "photo")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("createThread.photo")

            Button {
                Task { await viewModel.toggleVoiceRecording() }
            } label: {
                attachmentTile(
                    systemImage: viewModel.isRecordingVoice ? "stop.circle" : "mic",
                    tint: viewModel.isRecordingVoice ? .red : .white
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("createThread.voice")

            attachmentTile(
                systemImage: hasVoiceAttachment ? "waveform.path" : "chart.bar",
                tint: hasVoiceAttachment ? .green : .white.opacity(0.7)
            )

            attachmentTile(
                text: "GIF",
                tint: .white.opacity(0.55)
            )
        }
    }

    private var voiceDurationText: String {
        guard let duration = viewModel.voiceAttachmentDuration else { return "" }
        return format(duration: duration)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
    }

    private var tileBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.06),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func attachmentTile(systemImage: String? = nil, text: String? = nil, tint: Color = .white) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tileBackground)

            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(tint)
            } else if let text {
                Text(text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(tint)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func statusPill(systemImage: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white.opacity(0.72))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }

    private func format(duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CreateThreadView_Previews: PreviewProvider {
    static var previews: some View {
        CreateThreadView()
    }
}
