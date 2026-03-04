//  ExploreView.swift
//  Pulse
//  Created by Spencer Jones on 6/5/25.

import SwiftUI

struct ExploreView: View {
    private enum ExploreSection: String, CaseIterable, Identifiable {
        case users
        case boards

        var id: String { rawValue }

        var title: String {
            switch self {
            case .users: return "People"
            case .boards: return "Boards"
            }
        }
    }

    @State private var searchText = ""
    @State private var selectedSection: ExploreSection = .users
    @StateObject var viewModel = ExploreViewModel()

    private var filteredUsers: [User] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return viewModel.users }
        return viewModel.users.filter {
            $0.username.lowercased().contains(query)
            || $0.fullname.lowercased().contains(query)
        }
    }

    private var filteredBoards: [Board] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return viewModel.publicBoards }
        return viewModel.publicBoards.filter { $0.name.lowercased().contains(query) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Explore Section", selection: $selectedSection) {
                        ForEach(ExploreSection.allCases) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .animation(.snappy, value: selectedSection)

                    if selectedSection == .users {
                        usersContent
                    } else {
                        boardsContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .accessibilityIdentifier("explore.view")
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: User.self, destination: { user in
                ProfileView(user: user)
            })
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search people or boards")
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    @ViewBuilder
    private var usersContent: some View {
        if filteredUsers.isEmpty {
            AppEmptyStateCard(
                systemImage: "person.2",
                title: "No results found",
                message: "Try searching for a different name or username."
            ) {
                Button {
                    searchText = ""
                } label: {
                    Text("Show Suggestions")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryButtonStyle())
            }
        } else {
            AppSectionHeader(title: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Suggested For You" : "Results")

            AppSurfaceCard {
                VStack(spacing: 0) {
                    ForEach(Array(filteredUsers.enumerated()), id: \.element.id) { index, user in
                        NavigationLink(value: user) {
                            UserCell(user: user)
                        }
                        .buttonStyle(.plain)

                        if index < filteredUsers.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var boardsContent: some View {
        if filteredBoards.isEmpty {
            AppEmptyStateCard(
                systemImage: "square.stack.3d.up",
                title: "No boards found",
                message: "Try a different search term or create a board from a saved post."
            ) {
                Button {
                    searchText = ""
                } label: {
                    Text("Clear Search")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
        } else {
            AppSectionHeader(title: "Public Boards")

            AppSurfaceCard {
                VStack(spacing: 0) {
                    ForEach(Array(filteredBoards.enumerated()), id: \.element.id) { index, board in
                        HStack(spacing: 12) {
                            Image(systemName: board.isPublic ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(board.name)
                                    .font(.body)
                                    .fontWeight(.semibold)

                                Text("\(board.itemCount ?? 0) saved posts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 14)

                        if index < filteredBoards.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExploreView()
    }
}
