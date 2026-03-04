//  ActivityView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct ActivityView: View {
    private enum ActivityFilter: String, CaseIterable, Identifiable {
        case all
        case likes
        case follows
        case comments

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All"
            case .likes: return "Likes"
            case .follows: return "Follows"
            case .comments: return "Comments"
            }
        }

        func includes(_ type: ThreadNotificationType) -> Bool {
            switch self {
            case .all:
                return true
            case .likes:
                return type == .like || type == .reaction
            case .follows:
                return type == .follow
            case .comments:
                return type == .comment
            }
        }
    }

    @StateObject private var viewModel = ActivityViewModel()
    @State private var selectedFilter: ActivityFilter = .all

    private var filteredNotifications: [ThreadNotification] {
        viewModel.notifications.filter { selectedFilter.includes($0.type) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    filterBar

                    if filteredNotifications.isEmpty {
                        AppEmptyStateCard(
                            systemImage: "bell",
                            title: "No Activity Yet",
                            message: "Likes, comments, and follows will show up here as your circle grows."
                        ) {
                            NavigationLink {
                                ExploreView()
                            } label: {
                                Text("Find People")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(AppPrimaryButtonStyle())
                        }
                    } else {
                        AppSurfaceCard {
                            VStack(spacing: 0) {
                                ForEach(Array(filteredNotifications.enumerated()), id: \.element.id) { index, notification in
                                    activityRow(for: notification)

                                    if index < filteredNotifications.count - 1 {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .accessibilityIdentifier("activity.view")
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        InboxView()
                    } label: {
                        Image(systemName: "paperplane")
                            .font(.subheadline.weight(.semibold))
                    }
                    .accessibilityIdentifier("activity.messages")
                }
            }
            .refreshable {
                await viewModel.fetchNotifications()
            }
        }
        .task {
            await viewModel.fetchNotifications()
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(ActivityFilter.allCases) { filter in
                if selectedFilter == filter {
                    Button {
                        withAnimation(.snappy) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                } else {
                    Button {
                        withAnimation(.snappy) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }
            }
        }
    }

    private func activityRow(for notification: ThreadNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            CircularProfileImageView(user: notification.user, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                Text(activityText(for: notification))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if let subtitle = activitySubtitle(for: notification) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            Text(notification.timestamp.timestampString())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
    }

    private func activityText(for notification: ThreadNotification) -> String {
        let username = notification.user?.username ?? "Someone"

        switch notification.type {
        case .follow:
            return "\(username) started following you"
        case .like:
            return "\(username) liked your post"
        case .comment:
            return "\(username) commented on your post"
        case .reaction:
            return "\(username) reacted to your post"
        }
    }

    private func activitySubtitle(for notification: ThreadNotification) -> String? {
        switch notification.type {
        case .follow:
            return notification.user.map { "@\($0.username)" }
        case .like, .reaction:
            return notification.thread?.caption
        case .comment:
            return notification.thread?.caption
        }
    }
}

#Preview {
    ActivityView()
}
