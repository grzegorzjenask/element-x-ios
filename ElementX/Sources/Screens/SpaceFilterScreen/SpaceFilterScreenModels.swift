//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceFilterScreenViewModelAction {
    case done
}

struct SpaceFilterScreenViewState: BindableState {
    var filters = [SpaceFilterProxy]()
    
    var selectedFilters: [SpaceFilterProxy]
    var isAllChatsSelected: Bool {
        selectedFilters.isEmpty
    }
    
    var bindings: SpaceFilterScreenViewStateBindings
}

struct SpaceFilterScreenViewStateBindings { }

enum SpaceFilterScreenViewAction {
    case toggleFilter(SpaceFilterProxy)
    case toggleAllChats
    case confirm
    case cancel
}
