//
//  CreateGroupThreadView.swift
//  Pulse
//
//  Created by Codex on 2/28/26.
//

import SwiftUI

struct CreateGroupThreadView: View {
    @StateObject private var viewModel = CreateGroupThreadViewModel()
    @State private var createdThread: ChatThread?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader(title: "Group Name")

                        TextField("Weekend Crew", text: $viewModel.title)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: AppUI.controlCornerRadius, style: .continuous)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                }

                AppSectionHeader(title: "Select People")

                if viewModel.users.isEmpty && !viewModel.isLoading {
                    AppEmptyStateCard(
                        systemImage: "person.3",
                        title: "No One To Add",
                        message: "Once more people sign up, you can start group chats here."
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
                        createdThread = await viewModel.createGroup()
                    }
                } label: {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Group")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(viewModel.isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadUsers()
        }
        .navigationDestination(item: $createdThread) { thread in
            ChatThreadView(
                threadId: thread.id,
                threadSeed: thread,
                preferredTitle: thread.title
            )
        }
        .alert("Couldn't Create Group", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    NavigationStack {
        CreateGroupThreadView()
    }
}
