//
//  AppointmentsViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Combine
import Networking

enum AppointmentOwnershipFilter: CaseIterable, Hashable {
    case all
    case participating
    case createdByMe

    var param: String {
        switch self {
        case .all:
            return "all"
        case .participating:
            return "participant"
        case .createdByMe:
            return "organizer"
        }
    }

    var title: String {
        switch self {
        case .all:
            return "Все"
        case .participating:
            return "Я участвую"
        case .createdByMe:
            return "Мои мероприятия"
        }
    }
}

@MainActor
final class AppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedOwnershipFilter: AppointmentOwnershipFilter = .all
    @Published var selectedTags: Set<Tag> = []
    @Published private(set) var totalAppointmentsCount = 0
    @Published var totalPages: Int = 0
    @Published var page = 0

    private let service = AppNetworking.shared
    private var hasLoaded = false
    private var allAppointments: [Appointment] = []
    private var myCreatedAppointments: [Appointment] = []
    private var participatingAppointmentIDs: Set<UUID> = []
    private var currentPageAppointments: [Appointment] = []

    private var adminAppointmentIDs: Set<UUID> {
        Set(myCreatedAppointments.map(\.id))
    }

    func loadAppointments(force: Bool = false, page: Int) async {
        if hasLoaded && !force { return }
        if isLoading { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await refreshBadgeMetadata(page: page)
            try await reloadList(page: page, managesLoading: false)
            hasLoaded = true
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .appointmentsList)
        }
    }

    func reloadList(page: Int, managesLoading: Bool = true) async {
        if managesLoading {
            guard !isLoading else { return }
            isLoading = true
            error = nil
            defer { isLoading = false }
        }

        self.page = page

        do {
            let (fetched, pages) = try await fetchAppointments(page: page, filter: selectedOwnershipFilter)
            totalPages = pages
            cacheAppointments(fetched, for: selectedOwnershipFilter)
            currentPageAppointments = fetched
            appointments = applyTagFilter(to: fetched)
            if selectedOwnershipFilter == .all {
                totalAppointmentsCount = allAppointments.count
            }
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .appointmentsList)
            currentPageAppointments = []
            appointments = []
        }
    }

    func fetchAppointment(id: UUID) async -> Appointment? {
        if let cached = appointments.first(where: { $0.id == id }) {
            return cached
        }

        let resource = Resource<AppointmentDTO, GetAppointmentRequest>(
            request: GetAppointmentRequest(appointmentId: id)
        )
        do {
            let dto = try await NetworkTask.fetch(service, resource: resource)
            let appointment = dto.toAppointment(
                isParticipating: participatingAppointmentIDs.contains(dto.id),
                isAdmin: adminAppointmentIDs.contains(dto.id)
            )
            if !appointments.contains(where: { $0.id == appointment.id }) {
                appointments.append(appointment)
            }
            return appointment
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .joinAppointment)
            return nil
        }
    }

    func replaceAppointment(_ appointment: Appointment) {
        updateCachedAppointment(appointment)
        if let index = currentPageAppointments.firstIndex(where: { $0.id == appointment.id }) {
            currentPageAppointments[index] = appointment
        }
        appointments = applyTagFilter(to: currentPageAppointments)
    }

    func selectOwnershipFilter(_ filter: AppointmentOwnershipFilter) {
        guard selectedOwnershipFilter != filter else { return }
        selectedOwnershipFilter = filter
        Task { await reloadList(page: page) }
    }

    func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        appointments = applyTagFilter(to: currentPageAppointments)
    }

    func clearTagFilter() {
        selectedTags = []
        appointments = applyTagFilter(to: currentPageAppointments)
    }

    func resetAllFilters() {
        selectedOwnershipFilter = .all
        selectedTags = []
        Task { await reloadList(page: page) }
    }

    var hasActiveFilters: Bool {
        selectedOwnershipFilter != .all || !selectedTags.isEmpty
    }

    // MARK: - Private

    private func refreshBadgeMetadata(page: Int) async {
        async let participatingIDsTask = fetchParticipatingAppointmentIDs(page: 0)
        async let createdTask = fetchAppointments(page: page, filter: .createdByMe)

        participatingAppointmentIDs = await participatingIDsTask
        myCreatedAppointments = (try? await createdTask)?.0 ?? []
    }

    private func fetchAppointments(
        page: Int,
        filter: AppointmentOwnershipFilter
    ) async throws -> ([Appointment], Int) {
        let myRole: AppointmentOwnershipFilter? = filter == .all ? nil : filter
        let resource = Resource<PagginatedAnswerAppointmentsDTO, ListAppointmentsRequest>(
            request: ListAppointmentsRequest(page: page, myRole: myRole)
        )
        let dtos = try await NetworkTask.fetch(service, resource: resource)
        let appointments = dtos.items.map { dto in
            dto.toAppointment(
                isParticipating: filter == .participating || participatingAppointmentIDs.contains(dto.id),
                isAdmin: filter == .createdByMe || adminAppointmentIDs.contains(dto.id)
            )
        }
        return (appointments, dtos.totalPages)
    }

    private func fetchParticipatingAppointmentIDs(page: Int) async -> Set<UUID> {
        let apiService = service
        return await Task.detached(priority: .utility) {
            await Self.fetchParticipatingAppointmentIDs(service: apiService, page: page)
        }.value
    }

    private nonisolated static func fetchParticipatingAppointmentIDs(
        service: URLService,
        page: Int
    ) async -> Set<UUID> {
        let resource = Resource<PagginatedAnswerAppointmentsDTO, ListAppointmentsRequest>(
            request: ListAppointmentsRequest(page: page, myRole: .participating)
        )
        guard let dtos = try? await NetworkTask.fetch(
            service,
            resource: resource,
            priority: .utility
        ) else {
            return []
        }
        return Set(dtos.items.map(\.id))
    }

    private func cacheAppointments(_ fetched: [Appointment], for filter: AppointmentOwnershipFilter) {
        switch filter {
        case .all:
            allAppointments = fetched
        case .participating:
            participatingAppointmentIDs = Set(fetched.map(\.id))
        case .createdByMe:
            myCreatedAppointments = fetched
        }
    }

    private func updateCachedAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
        }
        if let index = allAppointments.firstIndex(where: { $0.id == appointment.id }) {
            allAppointments[index] = appointment
        }
        if let index = myCreatedAppointments.firstIndex(where: { $0.id == appointment.id }) {
            myCreatedAppointments[index] = appointment
        }
        if appointment.isParticipating {
            participatingAppointmentIDs.insert(appointment.id)
        }
    }

    private func applyTagFilter(to source: [Appointment]) -> [Appointment] {
        guard !selectedTags.isEmpty else { return source }
        return source.filter { appointment in
            !appointment.tags.filter { selectedTags.contains($0) }.isEmpty
        }
    }
}
