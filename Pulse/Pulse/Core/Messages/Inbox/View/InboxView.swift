//
//  InboxView.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import SwiftUI

struct InboxView: View {
    private enum InboxScope: String, CaseIterable, Identifiable {
        case inbox
        case requests

        var id: String { rawValue }

        var title: String {
            switch self {
            case .inbox: return "Inbox"
            case .requests: return "Requests"
            }
        }
    }

    @StateObject private var viewModel = InboxViewModel()
    @State private var selectedScope: InboxScope = .inbox

    private var visibleThreads: [UserChatThreadIndex] {
        switch selectedScope {
        case .inbox:
            return viewModel.inboxThreads
        case .requests:
            return viewModel.requestThreads
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                scopePicker

                if visibleThreads.isEmpty {
                    emptyState
                } else {
                    AppSurfaceCard {
                        VStack(spacing: 0) {
                            ForEach(Array(visibleThreads.enumerated()), id: \.element.id) { index, thread in
                                NavigationLink {
                                    ChatThreadView(
                                        threadId: thread.id,
                                        preferredTitle: thread.namePreview,
                                        preferredPhotoURL: thread.photoPreview
                                    )
                                } label: {
                                    threadRow(for: thread)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("inbox.row.\(thread.id)")

                                if index < visibleThreads.count - 1 {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CreateGroupThreadView()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("inbox.createGroup")
            }
        }
        .accessibilityIdentifier("inbox.view")
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.refresh()
        }
        .alert("Couldn't Load Messages", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var scopePicker: some View {
        HStack(spacing: 8) {
            ForEach(InboxScope.allCases) { scope in
                if selectedScope == scope {
                    Button {
                        withAnimation(.snappy) {
                            selectedScope = scope
                        }
                    } label: {
                        Text(scope.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .accessibilityIdentifier("inbox.scope.\(scope.rawValue)")
                } else {
                    Button {
                        withAnimation(.snappy) {
                            selectedScope = scope
                        }
                    } label: {
                        Text(scope.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                    .accessibilityIdentifier("inbox.scope.\(scope.rawValue)")
                }
            }
        }
    }

    private var emptyState: some View {
        AppEmptyStateCard(
            systemImage: selectedScope == .inbox ? "ellipsis.message" : "tray",
            title: selectedScope == .inbox ? "No Messages Yet" : "No Requests",
            message: selectedScope == .inbox
                ? "Your direct messages and group chats will show up here."
                : "Message requests will appear here until you accept them."
        ) {
            NavigationLink {
                ExploreView()
            } label: {
                Text("Find People")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppPrimaryButtonStyle())
        }
    }

    private func threadRow(for thread: UserChatThreadIndex) -> some View {
        HStack(alignment: .top, spacing: 12) {
            CircularProfileImageView(imageUrl: thread.photoPreview, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(thread.namePreview ?? defaultTitle(for: thread))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let unreadCount = thread.unreadCount, unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(.systemBackground))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.primary)
                            )
                    }

                    Spacer(minLength: 8)

                    Text(relativeTimestamp(for: thread.updatedAt.dateValue()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(thread.lastMessageText ?? fallbackMessage(for: thread))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 14)
    }

    private func defaultTitle(for thread: UserChatThreadIndex) -> String {
        thread.type == .group ? "Group" : "Conversation"
    }

    private func fallbackMessage(for thread: UserChatThreadIndex) -> String {
        thread.state == .requested ? "Open to review this message request." : "No messages yet."
    }

    private func relativeTimestamp(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        InboxView()
    }
}
