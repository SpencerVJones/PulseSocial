//  RegistrationView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct RegistrationView: View {
    @StateObject var viewModel = RegistrationViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            
            // Brand mark
            BrandedLogoView(size: 190)
                .padding()
            
            // Textfields
            VStack {
                TextField("Enter your email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .modifier(TextFieldModifier())
                
                SecureField("Enter your password", text: $viewModel.password)
                    .modifier(TextFieldModifier())
                
                TextField("Enter your full name", text: $viewModel.fullname)
                    .modifier(TextFieldModifier())
                
                TextField("Enter your username", text: $viewModel.username)
                    .modifier(TextFieldModifier())
            }
            
            // Sign Up Button
            Button {
                Task { try await viewModel.createUser() }
            } label: {
                Text("Sign Up")
                    .modifier(SignInButtonModifier())
            }
            .padding(.vertical)
            
            Spacer()
            
            Divider()
            
            // Login Button
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3){
                    Text("Already have an account?")
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.primary)
                .font(.footnote)
            }
            .accessibilityIdentifier("registration.signIn")
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    RegistrationView()
}
