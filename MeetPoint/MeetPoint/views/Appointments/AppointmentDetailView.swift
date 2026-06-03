//
//  AppointmentDetailView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 01.06.2026.
//

import SwiftUI

enum DetailTab: CaseIterable {
    case participants, statistics

    var title: String {
        switch self {
        case .participants: return "Участники"
        case .statistics:  return "Статистика"
        }
    }
}

private struct StatBlock: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPurple)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.appLightPurple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct AppointmentDetailView: View {
    @Environment(\.openURL) private var openURL

    @State private var displayedAppointment: Appointment
    var onAppointmentUpdated: ((Appointment) -> Void)?
    var onAppointmentDeleted: (() -> Void)?

    @StateObject private var viewModel = AppointmentDetailViewModel()
    @State private var selectedTab: DetailTab = .participants
    @State private var selectedUser: User?
    @State private var showEditAppointment = false
    @State private var showJoinTagsSheet = false
    @State private var joinTags: Set<Tag> = []
    @State private var usPage: Int = 0
    let curUserTags: [String]
    init(
        appointment: Appointment,
        onAppointmentUpdated: ((Appointment) -> Void)? = nil,
        onAppointmentDeleted: (() -> Void)? = nil,
        curUserTags: [String]
    ) {
        self.curUserTags = curUserTags
        _displayedAppointment = State(initialValue: appointment)
        self.onAppointmentUpdated = onAppointmentUpdated
        self.onAppointmentDeleted = onAppointmentDeleted
    }

    private var formattedDate: String {
        displayedAppointment.date.formatted(
            .dateTime.day().month(.wide).year()
            .locale(.russian)
        )
    }

    private var eventShareLink: String {
        AppNetworking.eventShareLink(for: displayedAppointment.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                eventHeader

                if !viewModel.isLoading {
                    joinEventSection
                }

                eventQRCard

                Divider()

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else if viewModel.isAdmin {
                    TabSwitcher(selected: $selectedTab)
                }

                if !viewModel.isLoading {
                    if viewModel.isAdmin {
                        switch selectedTab {
                        case .participants: participantsSection
                        case .statistics:  statisticsSection
                        }
                    } else {
                        participantsSection
                    }
                }
            }
            .padding(20)
        }
        .refreshable {
            await refreshAppointmentDetail()
        }
        .background(Color.appBackground)
        .navigationTitle(displayedAppointment.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isAdmin && !viewModel.isLoading {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditAppointment = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appYellow)
                    }
                    
                    .accessibilityLabel("Редактировать мероприятие")
                }
            }
        }
        .sheet(isPresented: $showEditAppointment) {
            EditAppointmentView(
                appointment: displayedAppointment,
                onUpdated: { updated in
                    displayedAppointment = updated
                    onAppointmentUpdated?(updated)
                },
                onDeleted: {
                    showEditAppointment = false
                    onAppointmentDeleted?()
                }
            )
        }
        .sheet(isPresented: $showJoinTagsSheet) {
            JoinTagsSheet(
                selectedTags: $joinTags,
                availableTags: displayedAppointment.tags,
                isSaving: viewModel.isRegistering,
                onConfirm: {
                    Task {
                        await viewModel.registerForAppointment(
                            appointmentId: displayedAppointment.id,
                            tags: joinTags
                        )
                        
                        if viewModel.error == nil {
                            showJoinTagsSheet = false
                        }
                    }
        },
                onCancel: { showJoinTagsSheet = false }
            )
        }
        .task { await viewModel.loadData(appointmentId: displayedAppointment.id, page: usPage) }
        .errorToast($viewModel.error)
        .sheet(item: $selectedUser) { user in
            let fallbackStatus: ConnectionStatusState? = {
                guard let id = user.id else { return nil }
                if viewModel.contactUserIds.contains(id) { return .contacts }
                if viewModel.requestsSentTo.contains(id) { return .outgoing(requestId: nil) }
                return nil
            }()
            let connectionStatus = user.id.flatMap { viewModel.connectionStatuses[$0] } ?? fallbackStatus
            let isContact = connectionStatus == .contacts
            let isCurrentUser = user.id.map { $0 == viewModel.currentUserId } ?? false
            VStack {
                UserCellSheet(
                    user: user,
                    isFriend: isContact,
                    hasOffer: false,
                    isSelf: isCurrentUser,
                    connectionState: connectionStatus
                )
                    .padding(.top, 24)
                Spacer()
            }
            .appScreenBackground()
            .presentationDetents([.medium])
            .presentationBackground(Color.appBackground)
            .task {
                guard !isCurrentUser else { return }
                await viewModel.loadConnectionStatus(for: user)
            }
        }
    }

    private func refreshAppointmentDetail() async {
        try? await QoSRunner.userInitiated {
            await viewModel.loadData(appointmentId: displayedAppointment.id, page: usPage)
        }
    }

    // MARK: Subviews

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label(formattedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("\(displayedAppointment.participantsCount)", systemImage: "person.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(displayedAppointment.description)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            FlowLayout(spacing: 6) {
                ForEach(displayedAppointment.tags) { tag in TagPill(tag: tag.rawValue, userTags: curUserTags) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var joinEventSection: some View {
        if !viewModel.isAdmin {
            if viewModel.isRegistered {
                Label("Вы участник мероприятия", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appLightPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.appLightPurple.opacity(0.4), lineWidth: 1)
                            )
                    )
            } else {
                Button {
                    joinTags = Set(displayedAppointment.tags)
                    showJoinTagsSheet = true
                } label: {
                    Group {
                        if viewModel.isRegistering {
                            ProgressView()
                                .tint(Color.appPurple)
                        } else {
                            Text("Присоединиться")
                                .font(.headline)
                                .foregroundStyle(Color.appPurple)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRegistering)
            }
        }
    }

    private struct JoinTagsSheet: View {
        @Binding var selectedTags: Set<Tag>
        let availableTags: [Tag]
        let isSaving: Bool
        let onConfirm: () -> Void
        let onCancel: () -> Void

        private var selectableTags: [Tag] {
            availableTags
                .reduce(into: [Tag]()) { result, tag in
                    guard !result.contains(tag) else { return }
                    result.append(tag)
                }
                .sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
        }

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Выберите теги")
                        .font(.headline)
                        .foregroundStyle(Color.appPurple)

                    Text("Мы покажем вас другим участникам по выбранным тегам.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Доступны только теги этого мероприятия.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(selectableTags) { tag in
                            customTagButton(tag)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if selectedTags.isEmpty {
                        Text("Нужно выбрать хотя бы один тег")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button("Отмена", action: onCancel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appMutedSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.primary)

                        Button(action: onConfirm) {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView()
                                        .tint(Color.appPurple)
                                }
                                Text(isSaving ? "Сохраняем..." : "Продолжить")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appYellow)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Color.appPurple)
                        }
                        .disabled(selectedTags.isEmpty || isSaving)
                        .opacity((selectedTags.isEmpty || isSaving) ? 0.7 : 1)
                    }
                }
                .padding(20)
                .background(Color.appBackground)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }

        private func customTagButton(_ tag: Tag) -> some View {
            let isSelected = selectedTags.contains(tag)
            return Button {
                if isSelected {
                    selectedTags.remove(tag)
                } else {
                    selectedTags.insert(tag)
                }
            } label: {
                Text(tag.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(isSelected ? Color.appPurple : .primary)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.appYellow : Color.appMutedSurface)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.appLightPurple.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var eventQRCard: some View {
        VStack(spacing: 14) {
            Text("QR-код для присоединения")
//                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appPurple)
                .frame(maxWidth: .infinity)

            Text("Отсканируйте камерой, чтобы присоединиться")
//                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Если приложение установлено — откроется оно. Иначе откроется сайт мероприятия.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            QRCodeImageView(content: eventShareLink, size: 200)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )

            if let shareURL = URL(string: eventShareLink) {
                Button {
                    openURL(shareURL)
                } label: {
                    Text(eventShareLink)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .underline()
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.plain)
            } else {
                Text(eventShareLink)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appLightPurple.opacity(0.4), lineWidth: 1)
                )
        )
    }

    @State private var isFiltersShowing = false
    @StateObject private var requestsViewModel = RequestsViewModel()

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Участники")
                    .fontWeight(.medium)
                Spacer()
                Button {
                    isFiltersShowing.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(viewModel.participantFilterTags.isEmpty ? Color.appPurple : Color.appLightPurple)
                }
            }

            if viewModel.isLoadingParticipants {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if viewModel.participants.isEmpty {
                Text(
                    viewModel.participantFilterTags.isEmpty
                        ? "Пока нет участников"
                        : "Нет участников с выбранными тегами"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.participants) { user in
                        let isCurrentUser = user.id.map { $0 == viewModel.currentUserId } ?? false
                        let cachedStatus = user.id.flatMap { viewModel.connectionStatuses[$0] }
                        let fallbackStatus: ConnectionStatusState? = {
                            guard let id = user.id else { return nil }
                            if viewModel.contactUserIds.contains(id) { return .contacts }
                            if viewModel.requestsSentTo.contains(id) { return .outgoing(requestId: nil) }
                            return nil
                        }()
                        let connectionStatus = cachedStatus ?? fallbackStatus
                        let isOrganizer = user.isEventOrganizer
                            || (isCurrentUser && viewModel.isAdmin)
                        Button { selectedUser = user } label: {
                            ParticipantRow(
                                user: user,
                                isAdmin: isOrganizer,
                                isCurrentUser: isCurrentUser,
                                connectionStatus: connectionStatus,
                                onConnect: {
                                    guard let userId = user.id else { return }
                                    QoSRunner.fireAndForgetUserInitiated {
                                        await viewModel.sendConnectionRequest(
                                            toUserId: userId,
                                            appointmentId: displayedAppointment.id
                                        )
                                    }
                                },
                                curUserTags: curUserTags,
                                requestsViewModel: requestsViewModel,
                                onConnectionAccepted: { userId in
                                    viewModel.applyConnectionAccepted(with: userId)
                                },
                                onConnectionDeclined: { userId in
                                    viewModel.applyConnectionDeclined(with: userId)
                                }
                                )
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .task {
                            guard !isCurrentUser else { return }
                            await viewModel.loadConnectionStatus(for: user)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isFiltersShowing) {
            ParticipantTagFilter(
                selectedTags: viewModel.participantFilterTags,
                onToggle: { tag in
                    var next = viewModel.participantFilterTags
                    if let index = next.firstIndex(of: tag) {
                        next.remove(at: index)
                    } else {
                        next.append(tag)
                    }
                    usPage = 0
                    viewModel.scheduleParticipantFilter(next, appointmentId: displayedAppointment.id, page: usPage)
                },
                onClear: {
                    usPage = 0
                    viewModel.scheduleParticipantFilter([], appointmentId: displayedAppointment.id, page: usPage)
                },
                allTags: displayedAppointment.allTags
            )
            .presentationDetents([.medium])
            .presentationBackground(Color.appBackground)
        }
    }

    @ViewBuilder
    private var statisticsSection: some View {
        if let stats = viewModel.stats {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatBlock(value: stats.registeredCount, label: "Зарегистрировались")
                    StatBlock(value: stats.requestsSent, label: "Запросов отправлено")
                }
                HStack(spacing: 12) {
                    StatBlock(value: stats.requestsAccepted, label: "Запросов принято")
                    StatBlock(value: stats.acquaintancesMade, label: "Знакомств состоялось")
                }
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
    }
}


private struct TabSwitcher: View {
    @Binding var selected: DetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = tab }
                } label: {
                    Text(tab.title)
                        .font(.subheadline)
                        .fontWeight(selected == tab ? .semibold : .regular)
                        .foregroundStyle(selected == tab ? Color.appPurple : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selected == tab ? Color.appYellow : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.appMutedSurface))
    }
}
