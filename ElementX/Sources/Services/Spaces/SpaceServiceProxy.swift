//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class SpaceServiceProxy: SpaceServiceProxyProtocol {
    private let spaceService: SpaceServiceProtocol
    
    private var topLevelSpacesHandle: TaskHandle?
    private let spacesSubject = CurrentValueSubject<[SpaceRoomProxyProtocol], Never>([])
    var topLevelSpacesPublisher: CurrentValuePublisher<[SpaceRoomProxyProtocol], Never> {
        spacesSubject.asCurrentValuePublisher()
    }
    
    private var spaceFilterHandle: TaskHandle?
    private let spaceFilterSubject = CurrentValueSubject<[SpaceFilterProxy], Never>([])
    var spaceFilterPublisher: CurrentValuePublisher<[SpaceFilterProxy], Never> {
        spaceFilterSubject.asCurrentValuePublisher()
    }
    
    init(spaceService: SpaceServiceProtocol) {
        self.spaceService = spaceService
        
        Task { await setupSubscriptions() }
    }
    
    private func setupSubscriptions() async {
        topLevelSpacesHandle = await spaceService.subscribeToTopLevelJoinedSpaces(listener: SDKListener { [weak self] updates in
            self?.handleUpdates(updates)
        })
        
        spaceFilterHandle = await spaceService.subscribeToSpaceFilters(listener: SDKListener { [weak self] updates in
            self?.handleSpaceFilterUpdates(updates)
        })
    }
    
    func spaceRoomList(spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError> {
        do {
            return try await .success(SpaceRoomListProxy(spaceService.spaceRoomList(spaceId: spaceID)))
        } catch {
            MXLog.error("Failed creating space room list for \(spaceID): \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func spaceForIdentifier(spaceID: String) async -> Result<SpaceRoomProxyProtocol?, SpaceServiceProxyError> {
        do {
            return try await .success(spaceService.getSpaceRoom(roomId: spaceID).map(SpaceRoomProxy.init))
        } catch {
            MXLog.error("Failed getting space room for \(spaceID): \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func leaveSpace(spaceID: String) async -> Result<LeaveSpaceHandleProxy, SpaceServiceProxyError> {
        do {
            return try await .success(.init(spaceID: spaceID, leaveHandle: spaceService.leaveSpace(spaceId: spaceID)))
        } catch {
            MXLog.error("Failed to get leave handle for \(spaceID): \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func joinedParents(childID: String) async -> Result<[SpaceRoomProxyProtocol], SpaceServiceProxyError> {
        do {
            return try await .success(spaceService.joinedParentsOfChild(childId: childID).map(SpaceRoomProxy.init))
        } catch {
            MXLog.error("Failed to get joined parents for \(childID): \(error)")
            return .failure(.sdkError(error))
        }
    }
        
    // MARK: - Private
    
    private func handleSpaceListUpdates(_ updates: [SpaceListUpdate]) {
        var spaces = spacesSubject.value
        
        for update in updates {
            switch update {
            case .append(let spaceRooms):
                spaces.append(contentsOf: spaceRooms.map(SpaceRoomProxy.init))
            case .clear:
                spaces.removeAll()
            case .pushFront(let spaceRoom):
                spaces.insert(SpaceRoomProxy(spaceRoom: spaceRoom), at: 0)
            case .pushBack(let spaceRoom):
                spaces.append(SpaceRoomProxy(spaceRoom: spaceRoom))
            case .popFront:
                spaces.removeFirst()
            case .popBack:
                spaces.removeLast()
            case .insert(let index, let spaceRoom):
                spaces.insert(SpaceRoomProxy(spaceRoom: spaceRoom), at: Int(index))
            case .set(let index, let spaceRoom):
                spaces[Int(index)] = SpaceRoomProxy(spaceRoom: spaceRoom)
            case .remove(let index):
                spaces.remove(at: Int(index))
            case .truncate(let length):
                spaces.removeSubrange(Int(length)..<spaces.count)
            case .reset(let spaceRooms):
                spaces = spaceRooms.map(SpaceRoomProxy.init)
            }
        }
        
        spacesSubject.send(spaces)
    }
    
    private func handleSpaceFilterUpdates(_ updates: [SpaceFilterUpdate]) {
        var filters = spaceFilterSubject.value
        
        for update in updates {
            switch update {
            case .append(let spaceFilters):
                filters.append(contentsOf: spaceFilters.map { buildSpaceFilter(from: $0) })
            case .clear:
                filters.removeAll()
            case .pushFront(let filter):
                filters.insert(buildSpaceFilter(from: filter), at: 0)
            case .pushBack(let filter):
                filters.append(buildSpaceFilter(from: filter))
            case .popFront:
                filters.removeFirst()
            case .popBack:
                filters.removeLast()
            case .insert(let index, let filter):
                filters.insert(buildSpaceFilter(from: filter), at: Int(index))
            case .set(let index, let filter):
                filters[Int(index)] = buildSpaceFilter(from: filter)
            case .remove(let index):
                filters.remove(at: Int(index))
            case .truncate(let length):
                filters.removeSubrange(Int(length)..<filters.count)
            case .reset(let spaceFilters):
                filters = spaceFilters.map { buildSpaceFilter(from: $0) }
            }
        }
        
        spaceFilterSubject.send(filters)
    }
    
    private func buildSpaceFilter(from filter: MatrixRustSDK.SpaceFilter) -> SpaceFilterProxy {
        SpaceFilterProxy(room: SpaceRoomProxy(spaceRoom: filter.spaceRoom),
                         level: UInt(max(filter.level, 0)),
                         descendants: Set(filter.descendants))
    }
}
