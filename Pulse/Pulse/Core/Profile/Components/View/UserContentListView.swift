//  UserContentListView.swift
//  Pulse
//  Created by Spencer Jones on 6/10/25


import SwiftUI

struct UserContentListView: View {
    @StateObject var viewModel: UserContentListViewModel
    @State private var selectedFilter: ProfileThreadFilter = .threads
    @Namespace private var animation
    
    // TODO: Change all hardcoded values to something like this
    private var filterBarWidth: CGFloat {
        let count = CGFloat(ProfileThreadFilter.allCases.count)
        return UIScreen.main.bounds.width / count - 16
    }
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: UserContentListViewModel(user: user))
    }
    
    var body: some View {
        VStack {
            HStack {
                ForEach(ProfileThreadFilter.allCases) { filter in
                    VStack {
                        Text(filter.title)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                        
                        if selectedFilter == filter {
                            Rectangle()
                                .foregroundColor(.primary)
                                .frame(width: filterBarWidth, height: 1)
                            // Makes bar slide
                                .matchedGeometryEffect(id: "item", in: animation)
                        } else {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: filterBarWidth, height: 1)
                        }
                    }
                    .onTapGesture {
                        // Makes bar slide (cont)
                        withAnimation(.spring()) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            
            contentSection
        }
        .padding(.vertical, 8)
        .task {
            await viewModel.refresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .postDidPublish)) { _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .commentDidPost)) { _ in
            Task { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch selectedFilter {
        case .threads:
            if viewModel.threads.isEmpty {
                emptyState(
                    title: "No Posts Yet",
                    systemImage: "text.bubble",
                    description: "Posts will show up here after they are published."
                )
            } else {
                LazyVStack {
                    ForEach(viewModel.threads) { thread in
                        ThreadCell(thread: thread)
                    }
                }
            }

        case .replies:
            if viewModel.replies.isEmpty {
                emptyState(
                    title: "No Replies Yet",
                    systemImage: "bubble.right",
                    description: "Replies and voice responses will show up here."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.replies) { reply in
                        replyCard(for: reply)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func replyCard(for reply: ThreadComment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                CircularProfileImageView(
                    user: reply.user,
                    imageUrl: reply.ownerProfileImageUrl,
                    size: .xSmall
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(reply.user?.username ?? reply.ownerUsername ?? "Anonymous")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if reply.isPendingSync {
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

                    Text("Replied \(reply.timestamp.timestampString())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !reply.commentText.isEmpty {
                Text(reply.commentText)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }

            if let voiceClipUrl = reply.voiceClipUrl {
                VoiceClipPlayerView(
                    audioUrl: voiceClipUrl,
                    duration: reply.voiceClipDuration
                )
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        }
        .padding(.horizontal)
    }

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }
}

//#Preview {
//    UserContentListView(user: User)
//}
