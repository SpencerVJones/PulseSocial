//  ForgotPasswordView.swift
//  Pulse
//
//  Created by Codex on 2/27/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            BrandedLogoView(size: 150)

            VStack(spacing: 10) {
                Text("Reset your password")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)

                Text("Enter the email address tied to your account and we'll send you a reset link.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            TextField("Enter your email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .modifier(TextFieldModifier())
                .accessibilityIdentifier("forgotPassword.email")

            Button {
                Task { await viewModel.sendResetEmail() }
            } label: {
                Text(viewModel.isSending ? "Sending..." : "Send Reset Link")
                    .modifier(SignInButtonModifier())
            }
            .disabled(viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            .opacity(viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending ? 0.6 : 1)
            .accessibilityIdentifier("forgotPassword.submit")

            Spacer()
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK") {
                if viewModel.didSendResetEmail {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
