//
//  ParticipantRow.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 01.06.2026.
//

import SwiftUI

struct ParticipantRow: View {
    let user: User
    let isAdmin: Bool
    let isCurrentUser: Bool
    let connectionStatus: ConnectionStatusState?
    let onConnect: () -> Void
    let curUserTags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.appPurple)
                    .lineLimit(2)
                    .truncationMode(.tail)
                Spacer()
                Text(user.position.rawValue)
                    .font(.caption)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(Color.appPurple)
                    .overlay(Capsule().stroke(Color.appPurple, lineWidth: 1))
            }

            FlowLayout(spacing: 6) {
                ForEach(user.tags) { tag in TagPill(tag: tag.rawValue, userTags: curUserTags) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isCurrentUser {
                HStack {
                    Spacer()
                    switch connectionStatus {
                    case .some(.contacts):
                        Text("Уже в друзьях")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.appMutedSurface)
                            .clipShape(Capsule())
                    case .some(.outgoing):
                        Label("Запрос отправлен", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.appLightPurple)
                    case .some(.incoming):
                        Label("Есть входящая заявка", systemImage: "envelope.badge")
                            .font(.subheadline)
                            .foregroundStyle(Color.appLightPurple)
                    case .some(.unknown(let raw)):
                        Label("Статус: \(raw)", systemImage: "questionmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    default:
                        Button(action: onConnect) {
                            Text("Хочу познакомиться")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.appPurple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.appYellow)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
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
