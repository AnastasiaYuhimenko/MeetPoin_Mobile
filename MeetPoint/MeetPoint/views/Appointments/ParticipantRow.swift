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
    let requestsViewModel: RequestsViewModel
    var onConnectionAccepted: ((UUID) -> Void)? = nil
    var onConnectionDeclined: ((UUID) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(user.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.appPurple)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    if isCurrentUser {
                        Text("(Вы)")
                            .font(.caption)
                    }
                    Spacer()
                    tagPillProfession
                }
                if isAdmin {
                    Text("(Организатор)")
                        .font(.caption)
                }
            }

            FlowLayout(spacing: 6) {
                if user.tags.count <= 3 {
                    ForEach(user.tags) { tag in
                        TagPill(tag: tag.rawValue, userTags: curUserTags)
                    }
                } else {
                    ForEach(user.tags.prefix(3)) { tag in
                        TagPill(tag: tag.rawValue, userTags: curUserTags)
                    }

                    Text("+\(user.tags.count - 3)")
                        .font(.caption)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(Color.appPurple)
                        .overlay(Capsule().stroke(Color.appPurple, lineWidth: 1))
                }
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
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .some(.outgoing):
                        Label("Запрос отправлен", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.appLightPurple)
                    case .some(.incoming), .some(.declined):
                        HStack {
                            Button {
                                Task {
                                    guard let userId = user.id else { return }
                                    await requestsViewModel.declineByUserID(userId)
                                    onConnectionDeclined?(userId)
                                }
                            } label: {
                                Text("Отклонить")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.appPurple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(lineWidth: 1)
                                            .fill(Color.appLightPurple)
                                    )
                            }
                            Button {
                                Task {
                                    guard let userId = user.id else { return }
                                    await requestsViewModel.acceptByUserID(userId)
                                    onConnectionAccepted?(userId)
                                }
                            } label: {
                                Text("Принять заявку")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.appPurple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                    .background(Color.appYellow)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    case .some(.unknown(let raw)):
                        Text("ничего")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.clear)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(lineWidth: 1)
                                    .fill(Color.clear)
                            )
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
            } else {
                Text("ничего")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.clear)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(lineWidth: 1)
                            .fill(Color.clear)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appYellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appLightPurple.opacity(0.35), lineWidth: 1)
//                        .frame(minHeight: 300)
                )
                .frame(minHeight: 144)
        )
        .frame(minHeight: 144)
        
    }

    private var tagPillProfession: some View {
        Text(user.position.rawValue)
            .font(.caption)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(Color.appPurple)
            .overlay(Capsule().stroke(Color.appPurple, lineWidth: 1))
    }
}
