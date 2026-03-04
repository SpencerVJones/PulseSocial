//  CurrentUserProfileView.swift
//  Pulse
//  Created by Spencer Jones on 6/10/25.

import SwiftUI

struct CurrentUserProfileView: View {
    @StateObject var viewModel = CurrentUserProfileViewModel()
    @State private var showEditProfile = false
    @State private var showSettings = false
   
    
    private var currentUser: User? {
        return viewModel.currentUser
    }
    
    var body: some View {
        NavigationStack {
            ScrollView (showsIndicators: false) {
                // Header
                VStack (spacing: 20) {
                    ProfileHeaderView(
                        user: currentUser,
                        followerCount: viewModel.followerCount,
                        followingCount: viewModel.followingCount
                    )
                    
                    
                    // Follow button
                    Button {
                        showEditProfile.toggle()
                    } label: {
                        Text("Edit Profile")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            }
                    }
                    
                    // User content list view
                    if let user = currentUser{
                        UserContentListView(user: user)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile, content: {
                if let user = currentUser {
                    EditProfileView(user: user)
                }
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(user: currentUser)
            }
            .padding(.horizontal)
            .task {
                await viewModel.refreshFollowCounts()
            }
        }

    }
}

// TODO: Update all views previews
struct CurrentUserProfileView_Previews : PreviewProvider {
    static var previews: some View {
        CurrentUserProfileView()
            .environmentObject(ThemeManager())
    }
}
