//
//  ThreadBoardsSheet.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import SwiftUI

struct ThreadBoardsSheet: View {
    @StateObject private var viewModel: ThreadBoardsViewModel

    init(thread: Thread) {
        self._viewModel = StateObject(wrappedValue: ThreadBoardsViewModel(thread: thread))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Save to board") {
                    ForEach(viewModel.boards) { board in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(board.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(board.isPublic ? "Public board" : "Private board")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if let boardId = board.boardId, viewModel.savedBoardIDs.contains(boardId) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button("Save") {
                                    Task { await viewModel.save(to: board) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.primary)
                            }
                        }
                    }
                }

                Section("Create board") {
                    TextField("Board name", text: $viewModel.newBoardName)
                    Toggle("Public board", isOn: $viewModel.newBoardIsPublic)

                    Button("Create Board") {
                        Task { await viewModel.createBoard() }
                    }
                    .disabled(viewModel.newBoardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Boards")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchBoards()
            }
            .alert("Board Error", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}
