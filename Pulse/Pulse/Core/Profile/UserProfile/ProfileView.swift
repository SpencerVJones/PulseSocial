//  ProfileView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct ProfileView: View {
    private struct ChatRoute: Identifiable, Hashable {
        let id = UUID()
        let thread: ChatThread
    }

    @StateObject private var viewModel: ProfileViewModel
    @State private var activeChatRoute: ChatRoute?
    @State private var isOpeningChat = false
    @State private var chatErrorMessage = ""
    @State private var showChatError = false

    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
        
    var body: some View {
        
            ScrollView (showsIndicators: false) {
                // Header
                VStack (spacing: 20) {
                    ProfileHeaderView(
                        user: viewModel.user,
                        followerCount: viewModel.followerCount,
                        followingCount: viewModel.followingCount
                    )
                    
                    if !viewModel.isCurrentUser {
                        HStack(spacing: 10) {
                            Button {
                                Task { await viewModel.toggleFollow() }
                            } label: {
                                Text(viewModel.isFollowing ? "Following" : "Follow")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(viewModel.isFollowing ? .primary : Color(.systemBackground))
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .background(viewModel.isFollowing ? .clear : .primary)
                                    .cornerRadius(8)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    }
                            }

                            Button {
                                Task {
                                    await openDirectMessage()
                                }
                            } label: {
                                Group {
                                    if isOpeningChat {
                                        ProgressView()
                                            .tint(.primary)
                                            .frame(maxWidth: .infinity, minHeight: 32)
                                    } else {
                                        Text("Message")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity, minHeight: 32)
                                    }
                                }
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                }
                            }
                            .foregroundStyle(.primary)
                            .disabled(isOpeningChat)

                            Button {
                                Task { await viewModel.toggleCloseFriend() }
                            } label: {
                                Label(viewModel.isCloseFriend ? "Close" : "Add Close", systemImage: viewModel.isCloseFriend ? "star.fill" : "star")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 32)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(Capsule())
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    
                    // User content list view
                    UserContentListView(user: viewModel.user)
                }
            }

            .navigationBarTitleDisplayMode(.inline)
            .padding(.horizontal)
            .task {
                await viewModel.refresh()
            }
            .navigationDestination(item: $activeChatRoute) { route in
                ChatThreadView(
                    threadId: route.thread.id,
                    threadSeed: route.thread,
                    preferredTitle: viewModel.user.fullname,
                    preferredPhotoURL: viewModel.user.profileImageUrl
                )
            }
            .alert("Couldn't Open Chat", isPresented: $showChatError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(chatErrorMessage)
            }
        
    }

    @MainActor
    private func openDirectMessage() async {
        guard !isOpeningChat else { return }

        isOpeningChat = true
        defer { isOpeningChat = false }

        do {
            let thread = try await ChatService.createOrOpenDirectThread(with: viewModel.user)
            activeChatRoute = ChatRoute(thread: thread)
        } catch {
            chatErrorMessage = error.localizedDescription
            showChatError = true
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
    ProfileView(user: dev.user)
    }
}
