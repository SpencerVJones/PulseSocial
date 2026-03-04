//  RegistrationViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/6/25.

import Foundation

class RegistrationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullname = ""
    @Published var username = ""
    
    @MainActor
    func createUser() async throws {
        print("DEBUG: Creating user here")
        try await AuthService.shared.createUser(
            withEmail: email,
            password: password,
            fullname: fullname,
            username: username)
    }
}
