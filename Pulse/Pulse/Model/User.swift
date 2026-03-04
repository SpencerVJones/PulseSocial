//  User.swift
//  Pulse
//  Created by Spencer Jones on 6/6/25

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let fullname: String
    let email: String
    let username: String
    var profileImageUrl: String?
    var bio: String?
    var fcmToken: String?
    var isFollowed: Bool?
    var followerCount: Int?
    var followingCount: Int?
}
