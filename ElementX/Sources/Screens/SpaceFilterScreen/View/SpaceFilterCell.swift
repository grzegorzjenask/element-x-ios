//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SpaceFilterCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let filter: SpaceFilterProxy
    let selected: Bool
    let mediaProvider: MediaProviderProtocol!
        
    private let verticalInsets = 12.0
    private let horizontalInsets = 16.0
    
    let action: (SpaceFilterProxy) -> Void

    var body: some View {
        Button {
            action(filter)
        } label: {
            HStack(spacing: 12.0) {
                if selected {
                    CompoundIcon(\.checkCircle)
                        .foregroundColor(.compound.iconSuccessPrimary)
                } else {
                    CompoundIcon(\.circle)
                        .foregroundColor(.compound.iconSecondary)
                }
                
                HStack(spacing: 8.0) {
                    if filter.level > 0 {
                        Image(systemSymbol: .arrowRight)
                            .foregroundColor(.compound.iconSecondary)
                    }
                    
                    HStack(spacing: 12.0) {
                        avatar
                        
                        content
                            .padding(.vertical, verticalInsets)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.compound.borderDisabled)
                                    .frame(height: 1 / UIScreen.main.scale)
                                    .padding(.trailing, -horizontalInsets)
                            }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.horizontal, horizontalInsets)
    }
    
    @ViewBuilder @MainActor
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: filter.room.avatar,
                            avatarSize: .room(on: .spaceFilters),
                            mediaProvider: mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
    
    private var content: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(filter.room.name)
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                
                ZStack {
                    // Hidden text to maintain consistent height.
                    Text("")
                        .hidden()
                    
                    if let alias = filter.room.canonicalAlias {
                        Text(alias)
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SpaceFilterCell_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = MediaProviderMock(configuration: .init())
    
    static let spaces = [SpaceRoomProxyProtocol].mockJoinedSpaces
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(spaces, id: \.id) { space in
                SpaceFilterCell(filter: .init(room: space, level: 0, descendants: .init()),
                                selected: false,
                                mediaProvider: mediaProvider) { _ in }
                SpaceFilterCell(filter: .init(room: space, level: 1, descendants: .init()),
                                selected: true,
                                mediaProvider: mediaProvider) { _ in }
            }
        }
    }
}
