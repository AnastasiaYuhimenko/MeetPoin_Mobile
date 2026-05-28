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

    private let service = AppNetworking.shared
    private let authService = AppNetworking.auth
    private var hasLoaded = false
    private var allAppointments: [Appointment] = []
    private var myCreatedAppointments: [Appointment] = []
    private var participatingAppointmentIDs: Set<UUID> = []
    private var adminAppointmentIDs: Set<UUID> {
        Set(myCreatedAppointments.map(\.id))
    }

    func loadAppointments(force: Bool = false) async {
        if hasLoaded && !force { return }
        if isLoading { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            allAppointments = try await fetchAllAppointments()
            async let myCreatedAppointmentsTask = fetchMyCreatedAppointments()
            async let participatingAppointmentsTask = fetchParticipatingAppointmentIDsInBackground(
                appointmentIDs: allAppointments.map(\.id)
            )
            myCreatedAppointments = (try? await myCreatedAppointmentsTask) ?? []
            participatingAppointmentIDs = await participatingAppointmentsTask
            totalAppointmentsCount = allAppointments.count

            applyFilters()
            hasLoaded = true
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .appointmentsList)
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
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
        }
        if let index = allAppointments.firstIndex(where: { $0.id == appointment.id }) {
            allAppointments[index] = appointment
        }
        if let index = myCreatedAppointments.firstIndex(where: { $0.id == appointment.id }) {
            myCreatedAppointments[index] = appointment
        }
        applyFilters()
    }

    func selectOwnershipFilter(_ filter: AppointmentOwnershipFilter) {
        selectedOwnershipFilter = filter
        applyFilters()
    }

    func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        applyFilters()
    }

    func clearTagFilter() {
        selectedTags = []
        applyFilters()
    }

    func resetAllFilters() {
        selectedOwnershipFilter = .all
        selectedTags = []
        applyFilters()
    }

    var hasActiveFilters: Bool {
        selectedOwnershipFilter != .all || !selectedTags.isEmpty
    }

    // MARK: - Private

    private func fetchAllAppointments() async throws -> [Appointment] {
        let resource = Resource<[AppointmentDTO], ListAppointmentsRequest>(
            request: ListAppointmentsRequest()
        )
        let dtos = try await NetworkTask.fetch(service, resource: resource)
        return dtos.map { $0.toAppointment() }
    }

    private func fetchMyCreatedAppointments() async throws -> [Appointment] {
        let resource = Resource<[AppointmentDTO], ListMyCreatedAppointmentsRequest>(
            request: ListMyCreatedAppointmentsRequest()
        )
        let dtos = try await NetworkTask.fetch(service, resource: resource)
        return dtos.map { $0.toAppointment() }
    }

    private func fetchParticipatingAppointmentIDsInBackground(
        appointmentIDs: [UUID]
    ) async -> Set<UUID> {
        let apiService = service
        let profileService = authService

        return await Task.detached(priority: .utility) {
            guard let currentUserId = await Self.fetchCurrentUserId(using: profileService) else {
                return []
            }

            return await Self.fetchParticipatingAppointmentIDs(
                appointmentIDs: appointmentIDs,
                currentUserId: currentUserId,
                service: apiService
            )
        }.value
    }

    private nonisolated static func fetchParticipatingAppointmentIDs(
        appointmentIDs: [UUID],
        currentUserId: UUID,
        service: URLService
    ) async -> Set<UUID> {
        guard !appointmentIDs.isEmpty else {
            return []
        }

        return await withTaskGroup(of: UUID?.self, returning: Set<UUID>.self) { group in
            for appointmentId in appointmentIDs {
                group.addTask {
                    let resource = Resource<[AppointmentParticipantDTO], GetAppointmentParticipantsRequest>(
                        request: GetAppointmentParticipantsRequest(
                            appointmentId: appointmentId,
                            filterTags: []
                        )
                    )
                    guard let participants = try? await NetworkTask.fetch(
                        service,
                        resource: resource,
                        priority: .utility
                    ) else {
                        return nil
                    }
                    let isParticipating = participants.contains { $0.id == currentUserId }
                    return isParticipating ? appointmentId : nil
                }
            }

            var ids: Set<UUID> = []
            for await appointmentId in group {
                if let appointmentId {
                    ids.insert(appointmentId)
                }
            }
            return ids
        }
    }

    private nonisolated static func fetchCurrentUserId(using authService: URLService) async -> UUID? {
        let resource = Resource<UserResponseDTO, GetMyProfileRequest>(
            request: GetMyProfileRequest()
        )
        guard let profile = try? await NetworkTask.fetch(
            authService,
            resource: resource,
            priority: .utility
        ) else {
            return nil
        }
        return UUID(uuidString: profile.id)
    }

    private func applyFilters() {
        let base: [Appointment]
        switch selectedOwnershipFilter {
        case .all:
            base = allAppointments
        case .participating:
            base = allAppointments.filter { participatingAppointmentIDs.contains($0.id) }
        case .createdByMe:
            base = myCreatedAppointments
        }

        let filteredByTags: [Appointment]
        if selectedTags.isEmpty {
            filteredByTags = base
        } else {
            let filteredTags = selectedTags
            filteredByTags = base.filter { appointment in
                !appointment.tags.filter(filteredTags.contains).isEmpty
            }
        }

        appointments = annotateAppointments(filteredByTags)
    }

    private func annotateAppointments(_ appointments: [Appointment]) -> [Appointment] {
        appointments.map { appointment in
            Appointment(
                id: appointment.id,
                title: appointment.title,
                date: appointment.date,
                description: appointment.description,
                tags: appointment.tags,
                participantsCount: appointment.participantsCount,
                isParticipating: participatingAppointmentIDs.contains(appointment.id),
                isAdmin: adminAppointmentIDs.contains(appointment.id)
            )
        }
    }
}
