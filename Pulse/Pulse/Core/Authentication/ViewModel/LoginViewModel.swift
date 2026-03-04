//  LoginViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/6/25

import Foundation

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    @MainActor
    func login() async throws {
        print("DEBUG: Logging in user here")
        try await AuthService.shared.login(withEmail: email, password: password)
    }
}
