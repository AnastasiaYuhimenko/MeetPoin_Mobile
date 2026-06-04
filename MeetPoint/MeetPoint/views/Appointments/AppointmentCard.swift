//
//  AppointmentCard.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 01.06.2026.
//

import SwiftUI

struct AppointmentCard: View {
    let appointment: Appointment
    let selectedTags: [String]
    
    private var formattedDate: String {
        appointment.date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .hour()
                .minute()
                .locale(.russian)
        )
    }

    @ViewBuilder
    private var roleBadges: some View {
        HStack(spacing: 6) {
            if appointment.isAdmin {
                TagPill(
                    tag: "Вы организатор",
                    userTags: ["Вы организатор"]
                )
            }
            if appointment.isParticipating {
                TagPill(
                    tag: "Вы участник",
                    userTags: []
                )
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack() {
                Text(appointment.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appPurple)
                    .lineLimit(2)
                    .truncationMode(.tail)

                Spacer()

                if appointment.isAdmin || appointment.isParticipating {
                    roleBadges
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.appLightPurple)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(Color.appLightPurple)
                Text("\(appointment.participantsCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)

            Text(appointment.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(minHeight: 40)

            FlowLayout(spacing: 6) {
                ForEach(appointment.allTags, id: \.self) { tag in
                    TagPill(tag: tag, userTags: selectedTags)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.appYellow.opacity(0.05))
                        .stroke(Color.appLightPurple.opacity(0.7), lineWidth: 1)
                )
                .glassEffect(.identity, in:  RoundedRectangle(cornerRadius: 20))
                .shadow(
                    color: .appLightPurple.opacity(0.15),
                    radius: 10
                )
        )
        
    }
}
