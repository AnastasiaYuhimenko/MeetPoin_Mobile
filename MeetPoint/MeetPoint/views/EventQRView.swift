//
//  EventQRView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI
import UIKit

struct EventQRView: View {

    let event: CreatedEvent
    var onDone: () -> Void

    @State private var copied = false
    @State private var showShareSheet = false

    private var shareLink: String {
        URLService.eventShareLink(for: event.id)
    }

    private var formattedDate: String {
        event.date.formatted(
            .dateTime.day().month(.wide).year().hour().minute()
                .locale(.russian)
        )
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    headerCard
                    qrCard
                    linkCard
                    actionsCard

                    if let token = event.adminToken, !token.isEmpty {
                        adminTokenCard(token: token)
                    }

                    Button(action: onDone) {
                        Text("Готово")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appPurple)
                            .frame(width: 220, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(Color.appYellow)
                            )
                    }
                    .padding(.top, 6)
                }
                .padding(20)
            }
        }
        .navigationTitle("Мероприятие создано")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareLink])
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.appPurple)

            Text(event.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPurple)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.appLightPurple)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !event.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(event.tags) { tag in
                        TagPill(tag: tag)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appLightPurple.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var qrCard: some View {
        VStack(spacing: 14) {
            Text("Отсканируйте камерой, чтобы присоединиться")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Если приложение установлено — откроется оно. Иначе откроется сайт мероприятия.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            QRCodeImageView(content: shareLink, size: 240)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appLightPurple.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var linkCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ссылка на мероприятие")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(shareLink)
                .font(.footnote)
                .foregroundStyle(Color.appPurple)
                .lineLimit(3)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appLightPurple.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appLightPurple.opacity(0.4), lineWidth: 1)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appLightPurple.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var actionsCard: some View {
        HStack(spacing: 12) {
            Button {
                UIPasteboard.general.string = shareLink
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { copied = true }
                QoSRunner.fireAndForgetUserInitiated {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation { copied = false }
                }
            } label: {
                Label(copied ? "Скопировано" : "Скопировать", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPurple)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.appPurple, lineWidth: 1)
                    )
            }

            Button {
                showShareSheet = true
            } label: {
                Label("Поделиться", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPurple)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appYellow)
                    )
            }
        }
    }

    private func adminTokenCard(token: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "key.fill")
                    .font(.caption)
                    .foregroundStyle(Color.appLightPurple)
                Text("Токен администратора")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPurple)
            }

            Text(token)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            Text("Сохраните токен — он понадобится для управления мероприятием.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appLightPurple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appLightPurple.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - UIActivityViewController bridge

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        EventQRView(
            event: CreatedEvent(
                id: UUID(),
                name: "Хакатон Промразработки",
                date: Date().addingTimeInterval(86400),
                description: "Большое мероприятие для разработчиков",
                tags: [.backend, .ai, .fintech],
                qrUrl: "meetpoint://event/12345",
                adminToken: "6ac01db991d2424eac77aa79b92874ca"
            ),
            onDone: {}
        )
    }
}
