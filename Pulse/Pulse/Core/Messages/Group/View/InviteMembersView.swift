//
//  InviteMembersView.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import SwiftUI

struct InviteMembersView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: InviteMembersViewModel

    init(threadId: String, existingMemberIds: Set<String>) {
        _viewModel = StateObject(
            wrappedValue: InviteMembersViewModel(
                threadId: threadId,
                existingMemberIds: existingMemberIds
            )
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.users.isEmpty && !viewModel.isLoading {
                    AppEmptyStateCard(
                        systemImage: "person.badge.plus",
                        title: "No One Left To Invite",
                        message: "Everyone available is already in this group."
                    ) {
                        EmptyView()
                    }
                } else {
                    AppSurfaceCard {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.users.enumerated()), id: \.element.id) { index, user in
                                Button {
                                    viewModel.toggleSelection(for: user.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        CircularProfileImageView(user: user, size: .small)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(user.fullname)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)

                                            Text("@\(user.username)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: viewModel.selectedUserIds.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(viewModel.selectedUserIds.contains(user.id) ? .primary : .secondary)
                                    }
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)

                                if index < viewModel.users.count - 1 {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                    }
                }

                Button {
                    Task {
                        if await viewModel.sendInvites() {
                            dismiss()
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Invites")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(viewModel.selectedUserIds.isEmpty || viewModel.isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Invite Members")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadUsers()
        }
        .alert("Couldn't Send Invites", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    NavigationStack {
        InviteMembersView(threadId: "preview", existingMemberIds: [])
    }
}
