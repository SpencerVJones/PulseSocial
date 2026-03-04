//
//  NotificationName+Thread.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import Foundation

extension Notification.Name {
    static let postDidPublish = Notification.Name("postDidPublish")
    static let commentDidPost = Notification.Name("commentDidPost")
    static let syncQueueDidChange = Notification.Name("syncQueueDidChange")
}
