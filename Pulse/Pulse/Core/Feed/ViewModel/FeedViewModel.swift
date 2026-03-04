//  FeedViewModel.swift
//  Pulse
//  Created by Spencer Jones on 6/13/25

import Foundation
import FirebaseAuth

@MainActor
class FeedViewModel: ObservableObject {
    @Published var threads = [Thread]()
    @Published var circles = [Circle]()
    @Published var selectedAlgorithm: FeedAlgorithm = .ranked {
        didSet {
            Task { await applyFilters() }
        }
    }
    @Published var selectedCircleId: String? {
        didSet {
            Task { await applyFilters() }
        }
    }
    @Published var hideReposts = false {
        didSet {
            Task { await applyFilters() }
        }
    }
    @Published var pendingOperationCount = 0
    @Published var isSyncingPendingChanges = false

    private var allThreads = [Thread]()
    private var followingIds = Set<String>()
    private var closeFriendIds = Set<String>()
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestMode")
    
    init() {
        Task {
            circles = await loadCircles()
            let cachedThreads = await OfflineSyncService.shared.cachedThreads()
            if !cachedThreads.isEmpty {
                allThreads = await OfflineSyncService.shared.mergedThreads(withRemote: cachedThreads)
                pendingOperationCount = await OfflineSyncService.shared.pendingOperationCount()
                await refreshRelationshipSets()
                await applyFilters()
            }

            await fetchThreads()
        }
    }
    
    func fetchThreads() async {
        if isUITesting {
            await loadUITestData()
            return
        }

        isSyncingPendingChanges = true
        pendingOperationCount = await OfflineSyncService.shared.syncPendingOperations()
        await refreshRelationshipSets()

        do {
            let fetchedThreads = try await ThreadService.fetchThreads()
            let hydratedThreads = await hydrateUsers(for: fetchedThreads)
            await OfflineSyncService.shared.saveCachedThreads(hydratedThreads)
            self.allThreads = await OfflineSyncService.shared.mergedThreads(withRemote: hydratedThreads)
        } catch {
            print("DEBUG: Failed to fetch feed posts: \(error.localizedDescription)")
            let cachedThreads = await OfflineSyncService.shared.cachedThreads()
            self.allThreads = await OfflineSyncService.shared.mergedThreads(withRemote: cachedThreads)
        }

        pendingOperationCount = await OfflineSyncService.shared.pendingOperationCount()
        isSyncingPendingChanges = false
        await applyFilters()
    }
    
    private func hydrateUsers(for sourceThreads: [Thread]) async -> [Thread] {
        var hydratedThreads = sourceThreads

        for index in hydratedThreads.indices {
            let ownerUid = hydratedThreads[index].ownerUid

            if ownerUid == UserService.shared.currentUser?.id {
                hydratedThreads[index].user = UserService.shared.currentUser
                continue
            }

            do {
                hydratedThreads[index].user = try await UserService.fetchUser(withUid: ownerUid)
            } catch {
                print("DEBUG: Failed to fetch post owner \(ownerUid): \(error.localizedDescription)")
            }
        }

        return hydratedThreads
    }

    func selectCircle(_ circleId: String?) {
        selectedCircleId = circleId
    }

    func refreshPendingState() async {
        pendingOperationCount = await OfflineSyncService.shared.pendingOperationCount()
    }

    private func applyFilters() async {
        var filteredThreads = allThreads
        let viewerId = Auth.auth().currentUser?.uid

        if let selectedCircleId {
            filteredThreads = filteredThreads.filter { $0.circleId == selectedCircleId }
        }

        if hideReposts {
            filteredThreads = filteredThreads.filter { $0.isRepost != true }
        }

        switch selectedAlgorithm {
        case .ranked:
            break
        case .newest:
            break
        case .followingOnly:
            filteredThreads = filteredThreads.filter { followingIds.contains($0.ownerUid) }
        case .closeFriends:
            filteredThreads = filteredThreads.filter { closeFriendIds.contains($0.ownerUid) }
        }

        if selectedAlgorithm == .newest {
            for index in filteredThreads.indices {
                filteredThreads[index].rankingScore = nil
            }
            threads = filteredThreads.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        } else {
            threads = FeedRankingService.rank(
                filteredThreads,
                viewerId: viewerId,
                followingIds: followingIds,
                closeFriendIds: closeFriendIds
            )
        }
    }

    private func refreshRelationshipSets() async {
        do {
            followingIds = try await FollowService.fetchFollowingIDs()
        } catch {
            followingIds = []
        }

        do {
            closeFriendIds = try await CloseFriendsService.fetchCloseFriendIDs()
        } catch {
            closeFriendIds = []
        }

        if let currentUid = Auth.auth().currentUser?.uid {
            followingIds.insert(currentUid)
            closeFriendIds.insert(currentUid)
        }
    }

    private func loadCircles() async -> [Circle] {
        if isUITesting {
            return CircleService.circles
        }

        return await CircleService.fetchCircles()
    }

    private func loadUITestData() async {
        circles = await loadCircles()
        allThreads = DeveloperPreview.shared.feedThreads
        followingIds = [DeveloperPreview.shared.user.id, "preview-user-2", "preview-user-3"]
        closeFriendIds = [DeveloperPreview.shared.user.id, "preview-user-2"]
        pendingOperationCount = 0
        isSyncingPendingChanges = false
        await applyFilters()
    }
}
