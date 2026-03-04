//  AppDesignSystem.swift
//  Pulse
//
//  Created by Codex on 2/27/26.
//

import SwiftUI

enum AppUI {
    static let cardCornerRadius: CGFloat = 14
    static let controlCornerRadius: CGFloat = 10
}

struct AppSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .tracking(0.4)
    }
}

struct AppSurfaceCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppUI.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.cardCornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

struct AppEmptyStateCard<ActionContent: View>: View {
    let systemImage: String
    let title: String
    let message: String
    private let actionContent: ActionContent

    init(
        systemImage: String,
        title: String,
        message: String,
        @ViewBuilder action: () -> ActionContent
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionContent = action()
    }

    var body: some View {
        AppSurfaceCard {
            VStack(spacing: 16) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 72, height: 72)

                    Image(systemName: systemImage)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                actionContent
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.systemBackground))
            .frame(minHeight: 44)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: AppUI.controlCornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.82 : 1))
            )
            .animation(.snappy, value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(minHeight: 44)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: AppUI.controlCornerRadius, style: .continuous)
                    .fill(Color(.tertiarySystemBackground).opacity(configuration.isPressed ? 0.7 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.controlCornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.22), lineWidth: 1)
            )
            .animation(.snappy, value: configuration.isPressed)
    }
}

struct AppDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.red.opacity(configuration.isPressed ? 0.72 : 1))
            .frame(minHeight: 44)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: AppUI.controlCornerRadius, style: .continuous)
                    .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: AppUI.controlCornerRadius, style: .continuous)
                            .fill(Color.red.opacity(0.05))
                    )
            )
            .animation(.snappy, value: configuration.isPressed)
    }
}
