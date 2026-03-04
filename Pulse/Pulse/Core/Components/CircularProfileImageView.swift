//  CircularProfileImageView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI
import Kingfisher

struct CircularProfileImageView: View {
    var user: User?
    var imageUrl: String? = nil
    let size: ProfileImageSize

    private var resolvedImageURL: URL? {
        guard let rawValue = (user?.profileImageUrl ?? imageUrl)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty else { return nil }

        return URL(string: rawValue)
    }

    private var defaultAvatar: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(Color(.systemGray5))

            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .padding(size.dimension * 0.22)
                .foregroundStyle(Color(.systemGray))
        }
        .frame(width: size.dimension, height: size.dimension)
    }
    
    var body: some View {
        if let resolvedImageURL {
            KFImage(resolvedImageURL)
                .placeholder {
                    defaultAvatar
                }
                .resizable()
                .scaledToFill()
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(SwiftUI.Circle())
        } else {
            defaultAvatar
        }
    }
}

struct CircularProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        CircularProfileImageView(user: dev.user, size: .medium)
    }
}

enum ProfileImageSize {
    case xxSmall
    case xSmall
    case small
    case medium
    case large
    case xLarge
    
    var dimension: CGFloat {
        switch self {
        case .xxSmall: return 28
        case .xSmall: return 32
        case .small: return 40
        case .medium: return 48
        case .large: return 64
        case .xLarge: return 80
        }
    }
    
}
