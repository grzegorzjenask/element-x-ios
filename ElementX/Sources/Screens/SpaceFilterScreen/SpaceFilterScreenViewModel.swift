//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceFilterScreenViewModelType = StateStoreViewModelV2<SpaceFilterScreenViewState, SpaceFilterScreenViewAction>

class SpaceFilterScreenViewModel: SpaceFilterScreenViewModelType, SpaceFilterScreenViewModelProtocol {
    private let spaceService: SpaceServiceProxyProtocol
    private let spaceFilterSubject: CurrentValueSubject<[SpaceFilterProxy], Never>
    
    private let actionsSubject: PassthroughSubject<SpaceFilterScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceFilterScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(spaceService: SpaceServiceProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         spaceFilterSubject: CurrentValueSubject<[SpaceFilterProxy], Never>) {
        self.spaceService = spaceService
        self.spaceFilterSubject = spaceFilterSubject
        
        super.init(initialViewState: SpaceFilterScreenViewState(selectedFilters: spaceFilterSubject.value,
                                                                bindings: .init()),
                   mediaProvider: mediaProvider)
        
        spaceService.spaceFilterPublisher.sink { [weak self] filters in
            self?.state.filters = filters
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceFilterScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .toggleFilter(let filter):
            if state.selectedFilters.contains(where: { $0.room.id == filter.room.id }) {
                state.selectedFilters.removeAll { $0.room.id == filter.room.id }
            } else {
                state.selectedFilters.append(filter)
            }
        case .toggleAllChats:
            state.selectedFilters.removeAll()
        case .confirm:
            spaceFilterSubject.send(state.selectedFilters)
            actionsSubject.send(.done)
        case .cancel:
            actionsSubject.send(.done)
        }
    }
}
