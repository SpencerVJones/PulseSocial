//  ThreadCell.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25

import SwiftUI
import Kingfisher

struct ThreadCell: View {
    private let thread: Thread
    @StateObject private var viewModel: ThreadCellViewModel
    @State private var showComments = false
    @State private var showBoards = false

    init(thread: Thread) {
        self.thread = thread
        self._viewModel = StateObject(wrappedValue: ThreadCellViewModel(thread: thread))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isRepostWrapper {
                repostHeader

                threadContentCard(
                    for: viewModel.displayThread,
                    embedded: true
                )
            } else {
                threadContentCard(for: viewModel.displayThread)
            }

            HStack(spacing: 16) {
                Button {
                    Task { await viewModel.toggleLike() }
                } label: {
                    Image(systemName: viewModel.displayThread.didLike == true ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.displayThread.didLike == true ? .red : .primary)
                }

                Button {
                    showComments.toggle()
                } label: {
                    Image(systemName: "bubble.right")
                        .foregroundStyle(.primary)
                }

                Menu {
                    ForEach(ThreadReactionType.allCases) { reaction in
                        Button("\(reaction.emoji) \(reaction.title)") {
                            Task { await viewModel.setReaction(reaction) }
                        }
                    }
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.primary)
                }

                Button {
                    showBoards = true
                } label: {
                    Image(systemName: "square.stack")
                        .foregroundStyle(.primary)
                }

                Button {
                    Task { await viewModel.repostThread() }
                } label: {
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundStyle(.primary)
                }
            }
            .font(.body)

            HStack(spacing: 12) {
                Text("\(viewModel.displayThread.likes) likes")
                Text("\(viewModel.displayThread.resolvedCommentCount) comments")

                ForEach(ThreadReactionType.allCases) { reaction in
                    let count = viewModel.displayThread.resolvedReactionCounts[reaction.rawValue] ?? 0
                    if count > 0 {
                        Text("\(reaction.emoji) \(count)")
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .task(id: thread.syncKey) {
            viewModel.updateThread(thread)
            await viewModel.prepareForDisplay()
        }
        .sheet(isPresented: $showComments) {
            ThreadCommentsView(thread: viewModel.displayThread) { updatedCommentCount in
                viewModel.setCommentCount(updatedCommentCount)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showBoards) {
            ThreadBoardsSheet(thread: viewModel.displayThread)
                .presentationDetents([.medium, .large])
        }
        .alert("Couldn't Repost", isPresented: $viewModel.showRepostAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.repostAlertMessage)
        }
        .alert(viewModel.deleteActionTitle == "Delete Repost" ? "Couldn't Delete Repost" : "Couldn't Delete Post", isPresented: $viewModel.showDeleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.deleteAlertMessage)
        }
    }

    private var repostHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            CircularProfileImageView(
                user: viewModel.thread.user,
                imageUrl: viewModel.thread.ownerProfileImageUrl,
                size: .xSmall
            )

            Label {
                Text("\(viewModel.thread.user?.username ?? viewModel.thread.ownerUsername ?? "Anonymous") reposted")
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 8) {
                if viewModel.thread.isPendingSync {
                    pendingBadge
                }

                Text(viewModel.thread.timestamp.timestampString())
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                threadActionMenu
            }
        }
    }

    @ViewBuilder
    private func threadContentCard(for thread: Thread, embedded: Bool = false) -> some View {
        let content = HStack(alignment: .top, spacing: 12) {
            CircularProfileImageView(
                user: thread.user,
                imageUrl: thread.ownerProfileImageUrl,
                size: .small
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(thread.user?.username ?? thread.ownerUsername ?? "Anonymous")
                        .font(.system(.footnote, design: .rounded))
                        .fontWeight(.semibold)

                    if let circleName = thread.circleName {
                        Text(circleName)
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        if thread.isPendingSync {
                            pendingBadge
                        }

                        Text(thread.timestamp.timestampString())
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if !embedded {
                            threadActionMenu
                        }
                    }
                }

                if !thread.caption.isEmpty {
                    Text(thread.caption)
                        .font(.system(.footnote, design: .rounded))
                        .multilineTextAlignment(.leading)
                        .lineLimit(embedded ? 4 : 6)
                }

                if let promptTitle = thread.promptTitle {
                    Text("Prompt: \(promptTitle)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                }

                if let imageUrl = thread.imageUrl, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: embedded ? 150 : 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let voiceClipUrl = thread.voiceClipUrl {
                    VoiceClipPlayerView(
                        audioUrl: voiceClipUrl,
                        duration: thread.voiceClipDuration
                    )
                }
            }
        }

        if embedded {
            content
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
        } else {
            content
        }
    }

    @ViewBuilder
    private var threadActionMenu: some View {
        if viewModel.canDeleteCurrentItem {
            Menu {
                Button(viewModel.deleteActionTitle, role: .destructive) {
                    Task { await viewModel.deleteCurrentItem() }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
    }

    private var pendingBadge: some View {
        Text("Pending")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
    }
}

struct ThreadCell_Previews: PreviewProvider {
    static var previews: some View {
        ThreadCell(thread: dev.thread)
    }
}

// TODO: Change all forgroundColor to forgroundStyle
