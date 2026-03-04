//  LoginView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationStack {
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
                        .accessibilityIdentifier("login.email")
                    
                    SecureField("Enter your password", text: $viewModel.password)
                        .modifier(TextFieldModifier())
                        .accessibilityIdentifier("login.password")
                }
                
                // Forgot Password Link
                NavigationLink {
                    ForgotPasswordView()
                } label: {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.vertical)
                        .padding(.trailing, 28)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Login Button
                Button {
                    Task { try await viewModel.login() }
                } label: {
                    Text("Login")
                        .modifier(SignInButtonModifier())
                }
                .accessibilityIdentifier("login.submit")
                Spacer()
                
                Divider()
                
                // Sign Up Link
                NavigationLink {
                    RegistrationView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack(spacing: 3){
                        Text("Don't have an account?")
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                    .font(.footnote)
                }
                .accessibilityIdentifier("login.signUpLink")
                .padding(.vertical, 16)
            }
        }
    }
}

#Preview {
    LoginView()
}
