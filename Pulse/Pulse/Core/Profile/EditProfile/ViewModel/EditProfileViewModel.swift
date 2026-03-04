//  EditProfileViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/11/25.

import SwiftUI
import PhotosUI

class EditProfileViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadImage() } }
    }
    @Published var profileImage: Image?
    @Published private(set) var isRemovingCurrentProfileImage = false
    private var uiImage: UIImage?
    
    func updateUserData(bio: String) async throws {
        print("DEBUG: Updating user data...")
        try await UserService.shared.updateBio(bio)
        if isRemovingCurrentProfileImage {
            try await UserService.shared.removeUserProfileImage()
        } else {
            try await updateProfileImage()
        }
        try await UserService.shared.fetchCurrentUser()
    }

    func markProfileImageForRemoval() {
        isRemovingCurrentProfileImage = true
        selectedItem = nil
        profileImage = nil
        uiImage = nil
    }
    
    @MainActor // MainActor fixes thread issue
    private func loadImage() async {
        guard let item = selectedItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        isRemovingCurrentProfileImage = false
        self.uiImage = uiImage
        self.profileImage = Image(uiImage: uiImage)
    }
    
    private func updateProfileImage() async throws {
        guard let image = self.uiImage else { return }
        let imageUrl = try await ImageUploader.uploadProfileImage(image)
        try await UserService.shared.updateUserProfileImage(withImageUrl: imageUrl)
    }
}
