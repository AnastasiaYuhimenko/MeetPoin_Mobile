//
//  AppointmentsFilterChip.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 01.06.2026.
//

import SwiftUI

struct AppointmentsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15))
                .fontWeight(.medium)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .layoutPriority(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.appPurple : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.appYellow : Color.appMutedSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.appLightPurple
                            .opacity(0.5))
                )
        }
        .buttonStyle(.plain)
    }
}
extension Appointments {
    var appointmentsFilters: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Фильтры")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPurple)
                Spacer()
                if viewModel.hasActiveFilters {
                    Button("Сбросить") {
                        viewModel.resetAllFilters()
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appLightPurple)
                    .padding(5)
                    .glassEffect()
                }
            }
            HStack(spacing: 8) {
                ForEach(AppointmentOwnershipFilter.allCases, id: \.self) { filter in
                    AppointmentsFilterChip(
                        title: filter.title,
                        isSelected: viewModel.selectedOwnershipFilter == filter
                    ) {
                        viewModel.selectOwnershipFilter(filter)
                    }
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text("По тегам")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(Tag.allCases) { tag in
                    AppointmentsFilterChip(
                        title: tag.rawValue,
                        isSelected: viewModel.selectedTags.contains(tag.apiValue)
                    ) {
                        viewModel.toggleTag(tag)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
        }
        
        .padding()
    }
}

struct ParticipantTagFilter: View {
    let selectedTags: [String]
    let onToggle: (String) -> Void
    let onClear: () -> Void
    let allTags: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Фильтр участников по тегам")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPurple)
                Spacer()
                if !selectedTags.isEmpty {
                    Button("Сбросить", action: onClear)
                        .font(.caption)
                        .foregroundStyle(Color.appLightPurple)
                }
            }

            Text(selectedTags.isEmpty
                 ? "Показаны все участники"
                 : "Участники с выбранными тегами")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)
                    Button {
                        onToggle(tag)
                    } label: {
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: true)
                            .layoutPriority(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? Color.appPurple : .primary)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color.appYellow : Color.appMutedSurface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appLightPurple.opacity(0.35), lineWidth: 1)
                )
        )
    }
}
