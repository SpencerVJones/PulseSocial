//  UserCell.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.
import SwiftUI

struct UserCell: View {
    @StateObject private var viewModel: UserFollowViewModel

    init(user: User) {
        self._viewModel = StateObject(wrappedValue: UserFollowViewModel(user: user))
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CircularProfileImageView(user: viewModel.user, size: .small)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.user.fullname)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text("@\(viewModel.user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !viewModel.isCurrentUser {
                if viewModel.isFollowing {
                    Button {
                        Task { await viewModel.toggleFollow() }
                    } label: {
                        Text("Following")
                            .frame(width: 108)
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                    .accessibilityIdentifier("userCell.follow.\(viewModel.user.username)")
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.7 : 1)
                } else {
                    Button {
                        Task { await viewModel.toggleFollow() }
                    } label: {
                        Text("Follow")
                            .frame(width: 108)
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .accessibilityIdentifier("userCell.follow.\(viewModel.user.username)")
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.7 : 1)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("userCell.\(viewModel.user.username)")
        .task {
            await viewModel.refreshState()
        }
    }
}

struct UserCell_Previews: PreviewProvider {
    static var previews: some View {
        UserCell(user: dev.user)
    }
}
