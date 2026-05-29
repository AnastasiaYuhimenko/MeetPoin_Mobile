//
//  Appointments.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI
import UIKit
// MARK: - Model

struct Appointment: Identifiable, Hashable {
    let id: UUID
    let title: String
    let date: Date
    let description: String
    let tags: [Tag]
    let participantsCount: Int

    /// Flags about current user's relation to the event
    let isParticipating: Bool
    let isAdmin: Bool

    init(
        id: UUID,
        title: String,
        date: Date,
        description: String,
        tags: [Tag],
        participantsCount: Int,
        isParticipating: Bool = false,
        isAdmin: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.description = description
        self.tags = tags
        self.participantsCount = participantsCount
        self.isParticipating = isParticipating
        self.isAdmin = isAdmin
    }
}

// MARK: - Shared Tag Pill

struct TagPill: View {
    let tag: Tag

    var body: some View {
        Text(tag.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
            .layoutPriority(3)
            .truncationMode(.tail)
            .frame(minWidth: 72, minHeight: 10)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appLightPurple.opacity(0.15))
            .foregroundStyle(Color.appPurple)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.appLightPurple.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Appointment Card

private struct AppointmentCard: View {
    let appointment: Appointment

    private var formattedDate: String {
        appointment.date.formatted(
            .dateTime.day().month(.wide).year()
            .locale(.russian)
        )
    }

    @ViewBuilder
    private var roleBadges: some View {
        HStack(spacing: 6) {
            if appointment.isAdmin {
                roleBadge(
                    text: "Вы организатор",
                    background: Color.appYellow.opacity(0.2)
                )
            }
            if appointment.isParticipating {
                roleBadge(
                    text: "Я участвую",
                    background: Color.appLightPurple.opacity(0.18)
                )
            }
        }
    }

    private func roleBadge(text: String, background: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(Color.appPurple)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.appLightPurple.opacity(0.35), lineWidth: 1)
            )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(appointment.title)
                    .font(.headline)
                    .foregroundStyle(Color.appPurple)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                    .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 20, alignment: .leading)


                Spacer(minLength: 8)

                if appointment.isAdmin || appointment.isParticipating {
                    roleBadges
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
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

            Text(appointment.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            FlowLayout(spacing: 6) {
                ForEach(appointment.tags) { tag in
                    TagPill(tag: tag)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appLightPurple.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

private struct AppointmentsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
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

// MARK: - Appointments List

struct Appointments: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @StateObject private var viewModel = AppointmentsViewModel()
    @State private var selectedAppointment: Appointment?
    @State private var showCreateEvent = false
    @State private var showScanner = false
    @State private var isResolvingDeepLink = false
    @State var page: Int = 0

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.totalAppointmentsCount == 0 {
                    ProgressView("Загружаем мероприятия...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.error != nil, viewModel.totalAppointmentsCount == 0 {
                    errorState
                } else if viewModel.totalAppointmentsCount == 0 {
                    emptyState
                } else {
                    appointmentsList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Мероприятия")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        authViewModel.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.red)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                }

                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appPurple)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                }

                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appYellow)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                }
            }
            .navigationDestination(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: appointment) { updated in
                    viewModel.replaceAppointment(updated)
                    selectedAppointment = updated
                }
            }
            .sheet(isPresented: $showCreateEvent, onDismiss: {
                QoSRunner.fireAndForgetUserInitiated {
                    await viewModel.loadAppointments(force: true, page: viewModel.page)
                }
            }) {
                CreateEventView()
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    QRScannerView { url in
                        deepLinkRouter.handle(url: url)
                    }
                }
            }
            .overlay {
                if isResolvingDeepLink {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        ProgressView("Открываем мероприятие...")
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.appCard)
                            )
                    }
                }
            }
            .task {
                viewModel.page = page
                try? await QoSRunner.userInitiated {
                    await viewModel.loadAppointments(page: page)
                }
            }
            .onChange(of: deepLinkRouter.pendingAppointmentId) { _, newValue in
                guard let id = newValue else { return }
                QoSRunner.fireAndForgetUserInitiated {
                    await openAppointment(id: id)
                }
            }
            .task {
                if let id = deepLinkRouter.pendingAppointmentId {
                    try? await QoSRunner.userInitiated {
                        await openAppointment(id: id)
                    }
                }
            }
            .errorToast($viewModel.error)
        }
    }

    private func openAppointment(id: UUID) async {
        showScanner = false
        showCreateEvent = false

        isResolvingDeepLink = true
        defer { isResolvingDeepLink = false }

        if let appointment = await viewModel.fetchAppointment(id: id) {
            selectedAppointment = appointment
        }
        deepLinkRouter.clearAppointment()
    }

    private var appointmentsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                appointmentsFilters

                if viewModel.appointments.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.appLightPurple)
                        Text("По выбранным фильтрам ничего не найдено")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        if viewModel.hasActiveFilters {
                            customButton(text: "Сбросить фильтры") {
                                viewModel.resetAllFilters()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.appointments) { appointment in
                            Button {
                                selectedAppointment = appointment
                            } label: {
                                AppointmentCard(appointment: appointment)
                                    .contentShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await refreshAppointments()
        }
    }

    private var appointmentsFilters: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Фильтры")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPurple)
                Spacer()
                if viewModel.hasActiveFilters {
                    Button("Сбросить") {
                        viewModel.resetAllFilters()
                    }
                    .font(.caption)
                    .foregroundStyle(Color.appLightPurple)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
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
                .padding(.horizontal, 1)
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
                        isSelected: viewModel.selectedTags.contains(tag)
                    ) {
                        viewModel.toggleTag(tag)
                    }
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

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.appLightPurple)
                Text("Нет мероприятий")
                    .font(.headline)
                    .foregroundStyle(Color.appPurple)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .refreshable {
            await refreshAppointments()
        }
    }

    private var errorState: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.appLightPurple)
                Text("Не удалось загрузить")
                    .font(.headline)
                    .foregroundStyle(Color.appPurple)
                Text("Причина показана в уведомлении сверху")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                customButton(text: "Повторить") {
                    QoSRunner.fireAndForgetUserInitiated {
                        await viewModel.loadAppointments(force: true, page: viewModel.page)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .refreshable {
            await refreshAppointments()
        }
    }

    private func refreshAppointments() async {
        try? await QoSRunner.userInitiated {
            await viewModel.loadAppointments(force: true, page: viewModel.page)
        }
    }
}

// MARK: - Detail Tab

private enum DetailTab: CaseIterable {
    case participants, statistics

    var title: String {
        switch self {
        case .participants: return "Участники"
        case .statistics:  return "Статистика"
        }
    }
}

// MARK: - Tab Switcher

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

// MARK: - Participant tag filter

private struct ParticipantTagFilter: View {
    let selectedTags: Set<Tag>
    let onToggle: (Tag) -> Void
    let onClear: () -> Void

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
                ForEach(Tag.allCases) { tag in
                    let isSelected = selectedTags.contains(tag)
                    Button {
                        onToggle(tag)
                    } label: {
                        Text(tag.rawValue)
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

// MARK: - Participant Row

private struct ParticipantRow: View {
    let user: User
    let isAdmin: Bool
    let isCurrentUser: Bool
    let connectionStatus: ConnectionStatusState?
    let onConnect: () -> Void

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
                ForEach(user.tags) { tag in TagPill(tag: tag) }
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

// MARK: - Stat Block

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

// MARK: - Detail View

struct AppointmentDetailView: View {
    @Environment(\.openURL) private var openURL

    @State private var displayedAppointment: Appointment
    var onAppointmentUpdated: ((Appointment) -> Void)?

    @StateObject private var viewModel = AppointmentDetailViewModel()
    @State private var selectedTab: DetailTab = .participants
    @State private var selectedUser: User?
    @State private var showEditAppointment = false
    @State private var showJoinTagsSheet = false
    @State private var joinTags: Set<Tag> = []
    @State private var usPage: Int = 0
    init(appointment: Appointment, onAppointmentUpdated: ((Appointment) -> Void)? = nil) {
        _displayedAppointment = State(initialValue: appointment)
        self.onAppointmentUpdated = onAppointmentUpdated
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
            EditAppointmentView(appointment: displayedAppointment) { updated in
                displayedAppointment = updated
                onAppointmentUpdated?(updated)
            }
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
                ForEach(displayedAppointment.tags) { tag in TagPill(tag: tag) }
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

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Участники")
                .fontWeight(.medium)
            ParticipantTagFilter(
                selectedTags: viewModel.participantFilterTags,
                onToggle: { tag in
                    var next = viewModel.participantFilterTags
                    if next.contains(tag) {
                        next.remove(tag)
                    } else {
                        next.insert(tag)
                    }
                    viewModel.scheduleParticipantFilter(next, appointmentId: displayedAppointment.id, page: usPage)
                },
                onClear: {
                    viewModel.scheduleParticipantFilter([], appointmentId: displayedAppointment.id, page: usPage)
                }
            )

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
                        Button { selectedUser = user } label: {
                            ParticipantRow(
                                user: user,
                                isAdmin: viewModel.isAdmin,
                                isCurrentUser: isCurrentUser,
                                connectionStatus: connectionStatus
                            ) {
                                guard let userId = user.id else { return }
                                QoSRunner.fireAndForgetUserInitiated {
                                    await viewModel.sendConnectionRequest(
                                        toUserId: userId,
                                        appointmentId: displayedAppointment.id
                                    )
                                }
                            }
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

#Preview {
    Appointments()
        .environmentObject(AuthViewModel())
        .environmentObject(DeepLinkRouter())
}
