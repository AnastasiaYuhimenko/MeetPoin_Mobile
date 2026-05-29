//
//  customTags.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import SwiftUI

struct customTags: View {
    @Binding var tags: Set<Tag>
    var maxSelection: Int = TagSelectionLimits.maximum

    private var isAtMaximum: Bool {
        tags.count >= maxSelection
    }

    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Tag.allCases) { tag in

                let isSelected = tags.contains(tag)
                let canSelect = isSelected || !isAtMaximum

                Button {
                    if isSelected {
                        tags.remove(tag)
                    } else if canSelect {
                        tags.insert(tag)
                    }
                } label: {
                    Text(tag.rawValue)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 5)
                        .background(
                            isSelected
                            ? Color.appYellow
                            : Color.appMutedSurface
                        )
                        .foregroundColor(
                            isSelected
                            ? .appPurple
                            : .primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSelect)
                .opacity(canSelect ? 1 : 0.45)
            }
        }
    }
}
