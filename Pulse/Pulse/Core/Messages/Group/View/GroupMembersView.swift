//
//  GroupMembersView.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import SwiftUI

struct GroupMembersView: View {
    @StateObject private var viewModel: GroupMembersViewModel

    init(threadId: String) {
        _viewModel = StateObject(wrappedValue: GroupMembersViewModel(threadId: threadId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if let thread = viewModel.thread {
                    AppSurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(thread.title ?? "Group")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text("\(viewModel.members.count) members")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if viewModel.members.isEmpty && !viewModel.isLoading {
                    AppEmptyStateCard(
                        systemImage: "person.3",
                        title: "No Members Found",
                        message: "Members will appear here once this group is set up."
                    ) {
                        EmptyView()
                    }
                } else {
                    AppSurfaceCard {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                                memberRow(for: member)

                                if index < viewModel.members.count - 1 {
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
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        InviteMembersView(
                            threadId: viewModel.threadId,
                            existingMemberIds: viewModel.memberIds
                        )
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .task {
            await viewModel.refresh()
        }
        .alert("Couldn't Update Group", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private func memberRow(for detail: ChatMemberDetail) -> some View {
        HStack(spacing: 12) {
            CircularProfileImageView(user: detail.user, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(detail.user.fullname)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if detail.membership.role == .admin {
                        Text("ADMIN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("@\(detail.user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if detail.membership.state == .requested {
                    Text("Invite pending")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if viewModel.isAdmin, detail.user.id != UserService.shared.currentUser?.id {
                Menu {
                    if detail.membership.role == .member {
                        Button("Promote to Admin") {
                            Task { await viewModel.promote(detail) }
                        }
                    } else {
                        Button("Make Member") {
                            Task { await viewModel.demote(detail) }
                        }
                    }

                    Button("Remove from Group", role: .destructive) {
                        Task { await viewModel.remove(detail) }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        GroupMembersView(threadId: "preview")
    }
}
