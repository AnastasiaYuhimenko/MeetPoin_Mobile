//
//  RequestsView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct RequestsView: View {
    @StateObject private var viewModel = RequestsViewModel()
    @State private var selectedUser: User?
    @State private var didRequestLoad = false
    let profileVIewModel = ProfileViewModel()
    var body: some View {
        
        NavigationStack {
            VStack {
                SkeletonCrossfade(
                    showsSkeleton: viewModel.shouldShowSkeleton,
                    minimumSkeletonDuration: 0.35
                ) {
                    requestsContent
                        .navigationTitle("Заявки")
                } skeleton: {
                    //                ScrollView {
                    RequestsSkeletonView()
                        .navigationTitle("Заявки")
                    //                }
                    //                .scrollDisabled(true)
                    //                .background(Color.appBackground)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.appBackground)
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    guard !didRequestLoad else { return }
                    didRequestLoad = true
                    Task {
                        await viewModel.loadRequests()
                    }
                }
                .errorToast($viewModel.error)
                .navigationDestination(item: $selectedUser) { user in
                    UserProfileDestination(
                        user: user,
                        connectionStatus: incomingConnectionStatus(for: user),
                        requestsViewModel: viewModel
                    )
                }
            }
        }
    }
    private var requestsContent: some View {
        ScrollView {
            if !viewModel.requests.isEmpty {
                requestsList
            } else if !viewModel.isLoading {
                requestsEmptyState
            } else {
                Color.clear
                    .containerRelativeFrame(.vertical)
            }
        }
        .refreshable {
            await refreshRequests()
        }
    }

    private func incomingConnectionStatus(for user: User) -> ConnectionStatusState {
        let requestId = viewModel.requests.first { $0.fromUser.id == user.id }?.id
        return .incoming(requestId: requestId)
    }

    private var requestsList: some View {
//        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.requests) { request in
                    RequestRow(
                        request: request,
                        onTap: { selectedUser = request.fromUser },
                        onAccept: {
                            QoSRunner.fireAndForgetUserInitiated {
                                await viewModel.acceptRequest(request.id)
                            }
                        },
                        onDecline: {
                            QoSRunner.fireAndForgetUserInitiated {
                                await viewModel.declineRequest(request.id)
                            }
                        }, curUserTags: profileVIewModel.selectedTags.map { $0.rawValue }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
//        }
        
    }

    private var requestsEmptyState: some View {
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
        .containerRelativeFrame(.vertical, alignment: .center)
        .padding()
    }

    private func refreshRequests() async {
        try? await QoSRunner.userInitiated {
            await viewModel.loadRequests(force: true)
        }
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
                    Text("Отклонить")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(.appPurple)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(lineWidth: 1)
                                .foregroundStyle(Color.appPurple)
                        )
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
                        .clipShape(RoundedRectangle(cornerRadius: 20))
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
