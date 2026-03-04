//
//  SettingsView.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import SwiftUI

struct SettingsView: View {
    let user: User?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showEditProfile = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showEditProfile = true
                    } label: {
                        HStack(spacing: 14) {
                            CircularProfileImageView(user: user, size: .large)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user?.fullname ?? "Your profile")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)

                                Text("@\(user?.username ?? "username")")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let email = user?.email, !email.isEmpty {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(user == nil)
                } header: {
                    AppSectionHeader(title: "Account")
                }

                Section {
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    AppSectionHeader(title: "Appearance")
                }

                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "bell.badge")
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Push Notifications")
                                .foregroundStyle(.primary)

                            Text("Disabled in this build. Enable when your Apple/Firebase setup is ready.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    AppSectionHeader(title: "Notifications")
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppDestructiveButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let user {
                    EditProfileView(user: user)
                }
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    AuthService.shared.signOut()
                    dismiss()
                }
            } message: {
                Text("You can sign back in at any time.")
            }
        }
    }
}

#Preview {
    SettingsView(user: DeveloperPreview.shared.user)
        .environmentObject(ThemeManager())
}
