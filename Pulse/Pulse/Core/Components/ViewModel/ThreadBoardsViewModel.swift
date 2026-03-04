//
//  ThreadBoardsViewModel.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import Foundation

@MainActor
final class ThreadBoardsViewModel: ObservableObject {
    @Published var boards = [Board]()
    @Published var savedBoardIDs = Set<String>()
    @Published var newBoardName = ""
    @Published var newBoardIsPublic = true
    @Published var isLoading = false
    @Published var errorMessage: String?

    let thread: Thread

    init(thread: Thread) {
        self.thread = thread
    }

    func fetchBoards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            boards = try await BoardService.fetchCurrentUserBoards()
            savedBoardIDs = []

            for board in boards {
                if let boardId = board.boardId, try await BoardService.isThreadSaved(thread, in: board) {
                    savedBoardIDs.insert(boardId)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createBoard() async {
        do {
            guard let board = try await BoardService.createBoard(name: newBoardName, isPublic: newBoardIsPublic) else { return }
            boards.insert(board, at: 0)
            newBoardName = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(to board: Board) async {
        do {
            try await BoardService.saveThread(thread, to: board)
            if let boardId = board.boardId {
                savedBoardIDs.insert(boardId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
