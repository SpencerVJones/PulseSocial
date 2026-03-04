//  EditProfileView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let user: User
    @State private var bio = ""
    @State private var link = ""
    @State private var isPrivateProfile = false
    @State private var showPhotoActions = false
    @State private var showPhotoPicker = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = EditProfileViewModel()

    private var canRemoveProfilePhoto: Bool {
        viewModel.profileImage != nil || !(user.profileImageUrl?.isEmpty ?? true)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                editorBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        editorHeader
                        profileEditorBody
                    }
                    .background(shellBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            bio = user.bio ?? ""
        }
        .confirmationDialog("Profile photo", isPresented: $showPhotoActions, titleVisibility: .visible) {
            Button("Choose from library") {
                showPhotoPicker = true
            }

            if canRemoveProfilePhoto {
                Button("Remove current photo", role: .destructive) {
                    viewModel.markProfileImageForRemoval()
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $viewModel.selectedItem, matching: .images)
        .alert("Couldn't Save Profile", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var editorBackground: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.03, green: 0.04, blue: 0.08),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shellBackground: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.04),
                Color(red: 0.05, green: 0.06, blue: 0.10),
                Color.black.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var editorHeader: some View {
        HStack {
            headerPillButton(title: "Cancel", action: {
                dismiss()
            })

            Spacer()

            Text("Edit Profile")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Spacer()

            headerPillButton(title: "Done", action: {
                Task {
                    do {
                        try await viewModel.updateUserData(bio: bio)
                        dismiss()
                    } catch {
                        saveErrorMessage = error.localizedDescription
                        showSaveError = true
                    }
                }
            })
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 24)
    }

    private var profileEditorBody: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                profileImageView

                Button("Edit picture or avatar") {
                    showPhotoActions = true
                }
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
            }
            .padding(.top, 8)
            .padding(.bottom, 34)

            formRow {
                HStack(alignment: .firstTextBaseline) {
                    Text("Name")
                        .foregroundStyle(.white)

                    Spacer()

                    Text(user.fullname)
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.trailing)
                }
            }

            rowDivider

            formRow {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Bio")
                        .foregroundStyle(.white)

                    TextField("Enter your bio", text: $bio, axis: .vertical)
                        .lineLimit(4)
                        .foregroundStyle(.white.opacity(0.92))
                        .tint(.white)
                }
            }

            rowDivider

            formRow {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Link")
                        .foregroundStyle(.white)

                    TextField("Add link...", text: $link)
                        .foregroundStyle(.white.opacity(0.92))
                        .tint(.white)
                }
            }

            rowDivider

            formRow {
                HStack {
                    Text("Private Profile")
                        .foregroundStyle(.white)

                    Spacer()

                    Toggle("", isOn: $isPrivateProfile)
                        .labelsHidden()
                        .tint(.green)
                }
            }

            Spacer(minLength: 220)
        }
        .font(.system(size: 20, weight: .regular))
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let image = viewModel.profileImage {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 132, height: 132)
                .clipShape(SwiftUI.Circle())
                .overlay {
                    SwiftUI.Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        } else {
            CircularProfileImageView(user: user, size: .xLarge)
                .frame(width: 132, height: 132)
                .overlay {
                    SwiftUI.Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private func headerPillButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.title3)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.02))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func formRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 18)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
    }
}

struct EditProfileView_Preview: PreviewProvider {
    static var previews: some View {
        EditProfileView(user: dev.user)
    }
}
