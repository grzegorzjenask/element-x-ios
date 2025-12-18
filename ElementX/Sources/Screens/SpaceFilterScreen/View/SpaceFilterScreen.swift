//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceFilterScreen: View {
    @Bindable var context: SpaceFilterScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                allChatsButton
                
                ForEach(context.viewState.filters, id: \.room.id) { filter in
                    let isSelected = context.viewState.selectedFilters.contains { $0.room.id == filter.room.id }
                    
                    SpaceFilterCell(filter: filter,
                                    selected: isSelected,
                                    mediaProvider: context.mediaProvider) { filter in
                        context.send(viewAction: .toggleFilter(filter))
                    }
                }
            }
        }
        .navigationTitle("Space filters")
        .toolbar { toolbar }
    }
    
    @ViewBuilder
    private var allChatsButton: some View {
        Button {
            context.send(viewAction: .toggleAllChats)
        } label: {
            HStack(spacing: 12.0) {
                if context.viewState.isAllChatsSelected {
                    CompoundIcon(\.checkCircle)
                        .foregroundColor(.compound.iconSuccessPrimary)
                } else {
                    CompoundIcon(\.circle)
                        .foregroundColor(.compound.iconSecondary)
                }
                
                Text("All chats")
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24.0)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.compound.borderDisabled)
                            .frame(height: 1 / UIScreen.main.scale)
                    }
            }
            .padding(.horizontal, 16)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            ToolbarButton(role: .cancel) {
                context.send(viewAction: .cancel)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            ToolbarButton(role: .done) {
                context.send(viewAction: .confirm)
            }
        }
    }
}

// MARK: - Previews

struct SpaceFilterScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()

    static var previews: some View {
        NavigationStack {
            SpaceFilterScreen(context: viewModel.context)
        }
    }
    
    static func makeViewModel() -> SpaceFilterScreenViewModel {
        SpaceFilterScreenViewModel(spaceService: SpaceServiceProxyMock(.populated),
                                   mediaProvider: MediaProviderMock(configuration: .init()),
                                   spaceFilterSubject: .init([]))
    }
}
