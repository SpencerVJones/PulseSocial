//  FeedView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    feedHeader
                    circleTabBar
                    Divider()
                        .padding(.horizontal)
                        .padding(.top, 14)

                    if viewModel.pendingOperationCount > 0 {
                        pendingSyncBanner
                            .padding(.top, 12)
                    }

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.threads) { thread in
                            ThreadCell(thread: thread)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .accessibilityIdentifier("feed.list")
            .refreshable {
                await viewModel.fetchThreads()
            }
            .onReceive(NotificationCenter.default.publisher(for: .postDidPublish)) { _ in
                Task { await viewModel.fetchThreads() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .syncQueueDidChange)) { _ in
                Task { await viewModel.refreshPendingState() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var feedHeader: some View {
        ZStack {
            Text("Pulse")
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                Spacer()
                filterMenu
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }

    private var circleTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                circleTab(label: "All", isSelected: viewModel.selectedCircleId == nil) {
                    viewModel.selectCircle(nil)
                }

                ForEach(viewModel.circles) { circle in
                    circleTab(label: circle.name, isSelected: viewModel.selectedCircleId == circle.id) {
                        viewModel.selectCircle(circle.id)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
        .padding(.horizontal)
    }

    private var filterMenu: some View {
        Menu {
            Button {
                Task { await viewModel.fetchThreads() }
            } label: {
                Label("Refresh Feed", systemImage: "arrow.clockwise")
            }

            Divider()

            Section("Sort") {
                ForEach(FeedAlgorithm.allCases) { algorithm in
                    Button {
                        viewModel.selectedAlgorithm = algorithm
                    } label: {
                        HStack {
                            Text(algorithm.title)

                            if viewModel.selectedAlgorithm == algorithm {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                viewModel.hideReposts.toggle()
            } label: {
                Label(
                    viewModel.hideReposts ? "Show Reposts" : "Hide Reposts",
                    systemImage: viewModel.hideReposts ? "arrow.uturn.backward.circle" : "arrow.2.squarepath"
                )
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.title3)
                .fontWeight(.medium)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .foregroundStyle(.primary)
        .accessibilityIdentifier("feed.filterMenu")
    }

    private var pendingSyncBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.isSyncingPendingChanges ? "arrow.triangle.2.circlepath.circle.fill" : "clock.arrow.circlepath")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.isSyncingPendingChanges ? "Syncing pending changes" : "\(viewModel.pendingOperationCount) change(s) waiting to sync")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("Posts, likes, and replies will reconcile automatically.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        }
        .padding(.horizontal)
        .accessibilityIdentifier("feed.pendingSyncBanner")
    }

    private func circleTab(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primary : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        FeedView()
    }
}
