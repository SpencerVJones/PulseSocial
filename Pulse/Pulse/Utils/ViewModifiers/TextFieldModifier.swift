//  TextFieldModifier.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

// Extract view modifiers for text fields into custom view modifier class
// Turns repeative code into professional clean code

struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 24)
    }
}
