//  PulseTabView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct PulseTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateThreadView = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "bolt.horizontal.circle.fill" : "bolt.horizontal.circle")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Pulse")
                }
                .accessibilityIdentifier("tab.feed")
                .onAppear { selectedTab = 0}
                .tag(0)
            
            ExploreView()
                .tabItem {
                    Image(systemName: "person.2.wave.2")
                    Text("People")
                }
                .accessibilityIdentifier("tab.explore")
                .onAppear { selectedTab = 1}
                .tag(1)
            
            //CreateThreadView()
            Text("")
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Post")
                }
                .accessibilityIdentifier("tab.create")
                .onAppear { selectedTab = 2}
                .tag(2)
            
            ActivityView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("Activity")
                }
                .accessibilityIdentifier("tab.activity")
                .onAppear { selectedTab = 3}
                .tag(3)
            
            CurrentUserProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                        .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                    Text("Studio")
                }
                .accessibilityIdentifier("tab.profile")
                .onAppear { selectedTab = 4}
                .tag(4)
        }
        // When create thread view is selected presents sheet view
        .onChange(of: selectedTab) {
            showCreateThreadView = selectedTab == 2
        }
        .sheet(isPresented: $showCreateThreadView, onDismiss: {
            // TODO: Change to remeber the most recent tab
            selectedTab = 0
        }, content: {
            CreateThreadView()
        })
        .tint(.primary)
        
    }
}

#Preview {
    NavigationStack {
        PulseTabView()
            .environmentObject(ThemeManager())
    }
}
