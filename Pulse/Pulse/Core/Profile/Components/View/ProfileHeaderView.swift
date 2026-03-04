//  ProfileHeaderView.swift
//  Pulse
//  Created by Spencer Jones on 6/10/25

import SwiftUI

struct ProfileHeaderView: View {
    var user: User?
    var followerCount: Int
    var followingCount: Int
    
    init(user: User?, followerCount: Int = 0, followingCount: Int = 0) {
        self.user = user
        self.followerCount = followerCount
        self.followingCount = followingCount
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CircularProfileImageView(user: user, size: .large)

            // Bio and stats
            VStack(alignment: .leading, spacing: 12) {
                // fullname and username
                VStack (alignment: .leading, spacing: 4) {
                    Text(user?.fullname ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(user?.username ?? "")
                        .font(.headline)
                }
                
                // Bio
                if let bio = user?.bio {
                    Text(bio)
                        .font(.footnote)
                }
                
                Text("\(followerCount) Followers · \(followingCount) Following")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHeaderView(user: dev.user, followerCount: 12, followingCount: 33)
    }
}
