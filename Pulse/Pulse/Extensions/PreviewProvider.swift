//  PreviewProvider.swift
//  Pulse
//  Created by Spencer Jones on 6/8/25

import Firebase
import SwiftUI

extension PreviewProvider {
    static var dev: DeveloperPreview {
        return DeveloperPreview.shared
    }
}

class DeveloperPreview {
    static let shared = DeveloperPreview()
    
    // Mock User
    let user = User(id: "preview-self", fullname: "Spencer Jones", email: "Spencer@example.com", username: "MakesSpence")
    let suggestedUser = User(id: "preview-user-2", fullname: "Alex Chen", email: "alex@example.com", username: "alexchen")
    let secondSuggestedUser = User(id: "preview-user-3", fullname: "Jordan Lee", email: "jordan@example.com", username: "jordanlee")
    
    // Mock Thread
    let thread: Thread
    let feedThreads: [Thread]
    let exploreUsers: [User]
    let activityNotifications: [ThreadNotification]

    private init() {
        var baseThread = Thread(
            ownerUid: user.id,
            operationId: "preview-post-1",
            caption: "This is a test post",
            timestamp: Timestamp(date: Date().addingTimeInterval(-600)),
            likes: 4,
            ownerUsername: user.username,
            ownerProfileImageUrl: user.profileImageUrl,
            circleId: "general",
            circleName: "General",
            commentCount: 2,
            didLike: false
        )
        baseThread.threadId = "preview-post-1"
        baseThread.user = user

        var rankedThread = Thread(
            ownerUid: suggestedUser.id,
            operationId: "preview-post-2",
            caption: "Shipping a better composer this week.",
            timestamp: Timestamp(date: Date().addingTimeInterval(-1_200)),
            likes: 9,
            ownerUsername: suggestedUser.username,
            ownerProfileImageUrl: suggestedUser.profileImageUrl,
            circleId: "build-in-public",
            circleName: "Build In Public",
            commentCount: 4,
            didLike: true
        )
        rankedThread.threadId = "preview-post-2"
        rankedThread.user = suggestedUser

        var closeFriendThread = Thread(
            ownerUid: secondSuggestedUser.id,
            operationId: "preview-post-3",
            caption: "Hot take: offline-first social apps feel better than spinner-first ones.",
            timestamp: Timestamp(date: Date().addingTimeInterval(-3_600)),
            likes: 6,
            ownerUsername: secondSuggestedUser.username,
            ownerProfileImageUrl: secondSuggestedUser.profileImageUrl,
            circleId: "hot-takes",
            circleName: "Hot Takes",
            commentCount: 1,
            didLike: false
        )
        closeFriendThread.threadId = "preview-post-3"
        closeFriendThread.user = secondSuggestedUser

        self.thread = baseThread
        self.feedThreads = [baseThread, rankedThread, closeFriendThread]
        self.exploreUsers = [suggestedUser, secondSuggestedUser]

        var likeNotification = ThreadNotification(
            type: .like,
            fromUid: suggestedUser.id,
            toUid: user.id,
            timestamp: Timestamp(date: Date().addingTimeInterval(-300)),
            threadId: baseThread.threadId,
            isRead: false
        )
        likeNotification.user = suggestedUser
        likeNotification.thread = baseThread

        var followNotification = ThreadNotification(
            type: .follow,
            fromUid: secondSuggestedUser.id,
            toUid: user.id,
            timestamp: Timestamp(date: Date().addingTimeInterval(-900)),
            threadId: nil,
            isRead: false
        )
        followNotification.user = secondSuggestedUser

        self.activityNotifications = [likeNotification, followNotification]
    }
}
