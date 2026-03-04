//  ForgotPasswordViewModel.swift
//  Pulse
//
//  Created by Codex on 2/27/26.
//

import Foundation

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isSending = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var didSendResetEmail = false

    func sendResetEmail() async {
        guard !isSending else { return }

        isSending = true
        defer { isSending = false }

        do {
            try await AuthService.shared.sendPasswordReset(toEmail: email)
            didSendResetEmail = true
            alertTitle = "Check Your Email"
            alertMessage = "If an account exists for \(email.trimmingCharacters(in: .whitespacesAndNewlines)), Firebase will send a password reset link."
            showAlert = true
        } catch {
            didSendResetEmail = false
            alertTitle = "Couldn't Reset Password"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
