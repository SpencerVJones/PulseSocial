//  ContentView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @State private var showLoadingScreen = !ProcessInfo.processInfo.arguments.contains("-UITestMode")
    private let isUITestingFeedFlow = ProcessInfo.processInfo.arguments.contains("-UITest_ShowFeed")
    private let forceLoggedOutForUITesting = ProcessInfo.processInfo.arguments.contains("-UITest_ForceLoggedOut")
    
    var body: some View {
        ZStack {
            destinationView
                .opacity(showLoadingScreen ? 0 : 1)

            if showLoadingScreen {
                BrandedLoadingView()
                    .transition(.opacity)
            }
        }
        .task {
            guard showLoadingScreen else { return }
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            withAnimation(.easeOut(duration: 0.2)) {
                showLoadingScreen = false
            }
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        if forceLoggedOutForUITesting {
            LoginView()
        } else if viewModel.userSession != nil || isUITestingFeedFlow {
            PulseTabView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
