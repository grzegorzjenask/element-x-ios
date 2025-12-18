//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a spaceFilter remove this comment once generating the final file

import Combine
import SwiftUI

struct SpaceFilterScreenCoordinatorParameters {
    let spaceService: SpaceServiceProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let spaceFilterSubject: CurrentValueSubject<[SpaceFilterProxy], Never>
}

enum SpaceFilterScreenCoordinatorAction {
    case done
}

final class SpaceFilterScreenCoordinator: CoordinatorProtocol {
    private let parameters: SpaceFilterScreenCoordinatorParameters
    private let viewModel: SpaceFilterScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SpaceFilterScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceFilterScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SpaceFilterScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SpaceFilterScreenViewModel(spaceService: parameters.spaceService,
                                               mediaProvider: parameters.mediaProvider,
                                               spaceFilterSubject: parameters.spaceFilterSubject)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .done:
                actionsSubject.send(.done)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpaceFilterScreen(context: viewModel.context))
    }
}
