//
//  ThemeManager.swift
//  Pulse
//
//  Created by Codex on 2/18/26.
//

import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    private enum Keys {
        static let selectedTheme = "selected_theme"
    }

    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Keys.selectedTheme)
        }
    }

    var preferredColorScheme: ColorScheme? {
        selectedTheme.colorScheme
    }

    init() {
        let rawValue = UserDefaults.standard.string(forKey: Keys.selectedTheme) ?? AppTheme.system.rawValue
        selectedTheme = AppTheme(rawValue: rawValue) ?? .system
    }
}
