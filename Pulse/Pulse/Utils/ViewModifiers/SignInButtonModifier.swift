//  SignInButtonModifier.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

// Extract view modifiers for text fields into custom view modifier class
// Turns repeative code into professional clean code

struct SignInButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(Color(.systemBackground))
            .frame(width: 352, height: 44)
            .background(Color.primary)
            .cornerRadius(8)
    }
}
