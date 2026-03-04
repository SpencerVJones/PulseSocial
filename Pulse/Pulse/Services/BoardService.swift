//
//  BoardService.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import FirebaseAuth
import FirebaseFirestore

struct BoardService {
    private static let db = Firestore.firestore()

    static func fetchCurrentUserBoards() async throws -> [Board] {
        guard let currentUid = Auth.auth().currentUser?.uid else { return [] }

        let snapshot = try await db.collection("boards")
            .whereField("ownerUid", isEqualTo: currentUid)
            .order(by: "timestamp", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Board.self) }
    }

    static func fetchPublicBoards() async throws -> [Board] {
        let snapshot = try await db.collection("boards")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Board.self) }
    }

    static func createBoard(name: String, isPublic: Bool) async throws -> Board? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let board = Board(
            ownerUid: currentUid,
            name: trimmedName,
            isPublic: isPublic,
            timestamp: Timestamp(),
            itemCount: 0
        )

        guard let boardData = try? Firestore.Encoder().encode(board) else { return nil }
        let ref = try await db.collection("boards").addDocument(data: boardData)
        let createdSnapshot = try await ref.getDocument()
        return try? createdSnapshot.data(as: Board.self)
    }

    static func saveThread(_ thread: Thread, to board: Board) async throws {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let boardId = board.boardId,
            let threadId = thread.threadId
        else { return }

        let itemRef = db.collection("boards")
            .document(boardId)
            .collection("items")
            .document(threadId)

        let existingSnapshot = try await itemRef.getDocument()
        let didExist = existingSnapshot.exists

        try await itemRef.setData(
            [
                "threadId": threadId,
                "savedByUid": currentUid,
                "timestamp": Timestamp()
            ],
            merge: true
        )

        if !didExist {
            try await db.collection("boards")
                .document(boardId)
                .updateData(["itemCount": FieldValue.increment(Int64(1))])
        }
    }

    static func isThreadSaved(_ thread: Thread, in board: Board) async throws -> Bool {
        guard let boardId = board.boardId, let threadId = thread.threadId else { return false }

        let snapshot = try await db.collection("boards")
            .document(boardId)
            .collection("items")
            .document(threadId)
            .getDocument()

        return snapshot.exists
    }
}
