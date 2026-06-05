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
    @Published var selectedTags: [String] = [] {
        didSet {
            self.page = 0
            Task {
                await reloadList(page: 0)
            }
        }
    }
    @Published private(set) var totalAppointmentsCount = 0
    @Published var totalPages: Int = 0
    @Published var page = 0

    private let service = AppNetworking.shared
    private var hasLoaded = false
    private var allAppointments: [Appointment] = []
    private var loadTask: Task<Void, Never>?

    func loadAppointments(force: Bool = false, page: Int) async {
        if hasLoaded && !force { return }

        if let loadTask {
            await loadTask.value
            return
        }

        let task = Task { @MainActor in
            if !hasLoaded || appointments.isEmpty {
                isLoading = true
            }
            defer {
                isLoading = false
                loadTask = nil
            }
            await performReload(page: page)
        }
        loadTask = task
        await task.value
    }

    func reloadList(page: Int, managesLoading: Bool = true) async {
        if managesLoading {
            if let loadTask {
                await loadTask.value
                return
            }

            let task = Task { @MainActor in
                isLoading = true
                defer {
                    isLoading = false
                    loadTask = nil
                }
                await performReload(page: page)
            }
            loadTask = task
            await task.value
            return
        }

        await performReload(page: page)
    }

    private func performReload(page: Int) async {
        self.page = page

        do {
            var pages = 0
            (self.appointments, pages) = try await fetchAppointments(
                page: page,
                filter: selectedOwnershipFilter,
                filterTags: selectedTags
            )
            self.totalPages = pages
            cacheAppointments(appointments, for: selectedOwnershipFilter)
            if selectedOwnershipFilter == .all {
                totalAppointmentsCount = allAppointments.count
            }
            error = nil
            hasLoaded = true
        } catch {
            hasLoaded = false
            self.error = UserFacingNetworkMessage.message(for: error, context: .appointmentsList)
            self.appointments = []
            if selectedOwnershipFilter == .all {
                totalAppointmentsCount = 0
            }
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
            let appointment = dto.toAppointment()
            if !appointments.contains(where: { $0.id == appointment.id }) {
                appointments.append(appointment)
            }
            self.error = nil
            return appointment
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .joinAppointment)
            return nil
        }
    }

    func replaceAppointment(_ appointment: Appointment) {
        updateCachedAppointment(appointment)
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
        }
    }

    func removeAppointment(id: UUID) {
        appointments.removeAll { $0.id == id }
        allAppointments.removeAll { $0.id == id }
        if selectedOwnershipFilter == .all {
            totalAppointmentsCount = allAppointments.count
        }
    }

    func selectOwnershipFilter(_ filter: AppointmentOwnershipFilter) {
        guard selectedOwnershipFilter != filter else { return }
        selectedOwnershipFilter = filter
        self.page = 0
        Task { await reloadList(page: page) }
    }

    func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag.apiValue) {
            let idx = selectedTags.firstIndex(of: tag.apiValue)
            if let idx {
                selectedTags.remove(at: idx)
            }
        } else {
            selectedTags.append(tag.apiValue)
        }
    }

    func clearTagFilter() {
        selectedTags = []
    }

    func resetAllFilters() {
        selectedOwnershipFilter = .all
        selectedTags = []
    }

    var hasActiveFilters: Bool {
        selectedOwnershipFilter != .all || !selectedTags.isEmpty
    }

    /// Скелет, пока идёт загрузка и на экране нечего показать (нет кэша).
    var shouldShowSkeleton: Bool {
        isLoading && appointments.isEmpty && error == nil
    }

    // MARK: - Private

    private func fetchAppointments(
        page: Int,
        filter: AppointmentOwnershipFilter,
        filterTags: [String]
    ) async throws -> ([Appointment], Int) {
        let myRole: AppointmentOwnershipFilter? = filter == .all ? nil : filter
        let resource = Resource<PagginatedAnswerAppointmentsDTO, ListAppointmentsRequest>(
            request: ListAppointmentsRequest(page: page, filtrTags: filterTags, myRole: myRole)
        )
        let dtos = try await NetworkTask.fetch(service, resource: resource)
        let appointments = dtos.items.map { dto in
            dto.toAppointment()
        }
        return (appointments, dtos.totalPages)
    }



    private func cacheAppointments(_ fetched: [Appointment], for filter: AppointmentOwnershipFilter) {
        switch filter {
        case .all:
            allAppointments = fetched
        case .participating:
            break
        case .createdByMe:
            break
        }
    }

    private func updateCachedAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
        }
        if let index = allAppointments.firstIndex(where: { $0.id == appointment.id }) {
            allAppointments[index] = appointment
        }
    }
}
