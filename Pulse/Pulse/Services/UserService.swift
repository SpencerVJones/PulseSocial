//  UserService.swift
//  Pulse
//  Created by Spencer Jones on 6/8/25

import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserService {
    @Published var currentUser: User?
    
    static let shared = UserService()
    
    init() {
        Task {try await fetchCurrentUser()}
    }
    
    @MainActor func fetchCurrentUser() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        var user = try snapshot.data(as: User.self)
        user.isFollowed = false
        user.followerCount = try await FollowService.fetchFollowerCount(for: uid)
        user.followingCount = try await FollowService.fetchFollowingCount(for: uid)
        self.currentUser = user
        
        print("DEBUG: Current user is \(user)")
    }
    
    
    // Function to fetch all users except current user
    static func fetchUsers() async throws -> [User] {
        guard let currentUid = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await Firestore.firestore().collection("users").getDocuments()
        var users = snapshot.documents.compactMap({try? $0.data(as: User.self)}).filter({$0.id != currentUid})

        for index in users.indices {
            let userId = users[index].id
            users[index].isFollowed = try await FollowService.isFollowing(uid: userId)
            users[index].followerCount = try await FollowService.fetchFollowerCount(for: userId)
            users[index].followingCount = try await FollowService.fetchFollowingCount(for: userId)
        }

        return users
    }
    
    static func fetchUser(withUid uid:String) async throws -> User? {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        var user = try snapshot.data(as: User.self)
        let currentUid = Auth.auth().currentUser?.uid
        user.isFollowed = currentUid == uid ? false : try await FollowService.isFollowing(uid: uid)
        user.followerCount = try await FollowService.fetchFollowerCount(for: uid)
        user.followingCount = try await FollowService.fetchFollowingCount(for: uid)
        return user
    }
    
    // For clearing the current user when signing out
    func reset() {
        self.currentUser = nil
    }
    
    @MainActor
    func updateUserProfileImage(withImageUrl imageUrl: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        try await Firestore.firestore().collection("users").document(currentUid).updateData(["profileImageUrl": imageUrl])
        self.currentUser?.profileImageUrl = imageUrl
    }

    @MainActor
    func removeUserProfileImage() async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        try await Firestore.firestore().collection("users").document(currentUid).updateData(["profileImageUrl": FieldValue.delete()])
        self.currentUser?.profileImageUrl = nil
    }

    @MainActor
    func updateBio(_ bio: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        try await Firestore.firestore().collection("users").document(currentUid).updateData(["bio": trimmedBio])
        self.currentUser?.bio = trimmedBio
    }
    
    @MainActor
    func refreshCurrentUserStats() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.currentUser?.followerCount = try await FollowService.fetchFollowerCount(for: uid)
        self.currentUser?.followingCount = try await FollowService.fetchFollowingCount(for: uid)
    }
    
}
