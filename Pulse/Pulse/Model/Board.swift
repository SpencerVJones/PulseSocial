//
//  Board.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import Firebase
import FirebaseFirestore

struct Board: Identifiable, Codable {
    @DocumentID var boardId: String?
    let ownerUid: String
    let name: String
    let isPublic: Bool
    let timestamp: Timestamp
    var itemCount: Int? = 0

    var id: String {
        boardId ?? UUID().uuidString
    }
}
