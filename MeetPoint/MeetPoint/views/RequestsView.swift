//
//  RequestsView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct RequestsView: View {
    @StateObject private var viewModel = RequestsViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var selectedUser: User?
    @State private var didRequestLoad = false

    var body: some View {
        NavigationStack {
            requestsScroll
                .background(Color.appBackground)
                .navigationTitle("Заявки")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(Color.appBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .onAppear {
                    guard !didRequestLoad else { return }
                    didRequestLoad = true
                    QoSRunner.fireAndForgetUserInitiated {
                        await viewModel.loadRequests()
                    }
                }
                .errorToast($viewModel.error)
                .sheet(item: $selectedUser) { user in
                    VStack {
                        UserCellSheet(user: user, isFriend: false, hasOffer: true)
                            .padding(.top, 24)
                        Spacer()
                    }
                    .appScreenBackground()
                    .presentationDetents([.medium])
                    .presentationBackground(Color.appBackground)
                }
        }
    }

    private var requestsScroll: some View {
        ScrollView {
            Group {
                if viewModel.isLoading && viewModel.requests.isEmpty {
                    ProgressView("Загружаем заявки...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 120)
                } else if viewModel.requests.isEmpty {
                    emptyStateContent
                } else {
                    requestsContent
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await refreshRequests()
        }
    }

    private var emptyStateContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color.appLightPurple)
            Text("Новых заявок нет")
                .font(.headline)
                .foregroundStyle(Color.appPurple)
            Text("Здесь появятся запросы на знакомство\nот участников мероприятий")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 120)
    }

    private var requestsContent: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.requests) { request in
                RequestRow(
                    request: request,
                    onTap: { selectedUser = request.fromUser },
                    onAccept: {
                        Task {
                            await viewModel.acceptRequest(request.id)
                        }
                    },
                    onDecline: {
                        Task {
                            await viewModel.declineRequest(request.id)
                        }
                    },
                    curUserTags: profileViewModel.selectedTags.map(\.rawValue)
                )
            }
        }
    }

    private func refreshRequests() async {
        await viewModel.loadRequests(force: true)
    }
}


// MARK: - Request Row

private struct RequestRow: View {
    let request: IncomingRequest
    let onTap: () -> Void
    let onAccept: () -> Void
    let onDecline: () -> Void
    let curUserTags: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Color.appLightPurple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.fromUser.displayName)
                            .font(.headline)
                            .foregroundStyle(Color.appPurple)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        Text(request.fromUser.position.rawValue)
                            .font(.caption)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: true)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            FlowLayout(spacing: 6) {
                ForEach(request.fromUser.tags) { tag in
                    TagPill(tag: tag.rawValue, userTags: curUserTags)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("Пропустить")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(.secondary)
                        .background(Color.appMutedSurface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onAccept) {
                    Text("Принять")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(Color.appPurple)
                        .background(Color.appYellow)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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

#Preview {
    RequestsView()
}
