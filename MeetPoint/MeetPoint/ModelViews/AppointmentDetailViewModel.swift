//
//  AppointmentDetailViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Combine
import SwiftUI
import Networking

struct AppointmentStats {
    let registeredCount: Int
    let requestsSent: Int
    let requestsAccepted: Int
    let acquaintancesMade: Int
}

// MARK: - Connections

enum ConnectionStatusState: Equatable {
    case noStatus
    case incoming(requestId: UUID?)
    case outgoing(requestId: UUID?)
    case contacts
    case unknown(raw: String)
    case declined(requestId: UUID?)

    init(status: String, requestId: UUID?) {
        let normalized = status.lowercased()
        switch normalized {
        case "contacts", "accepted", "friend", "friends":
            self = .contacts
        case "incoming", "incoming_request", "pending_incoming", "request_received":
            self = .incoming(requestId: requestId)
        case "outgoing", "outgoing_request", "pending_outgoing", "sent", "request_sent", "pending":
            self = .outgoing(requestId: requestId)
        case "none", "not_connected", "no_set", "not_set", "no_sent", "not_sent":
            self = .noStatus
        case "request_declined":
            self = .declined(requestId: requestId)
        default:
            self = .unknown(raw: status)
        }
    }

    var isRequestSent: Bool {
        if case .outgoing = self { return true }
        return false
    }

    var requestId: UUID? {
        switch self {
        case .incoming(let id), .outgoing(let id), .declined(let id):
            return id
        default:
            return nil
        }
    }
}

@MainActor
final class AppointmentDetailViewModel: ObservableObject {
    @Published var participants: [User] = []
    @Published var participantFilterTags: [String] = []
    @Published var stats: AppointmentStats?
    @Published var isLoading = false
    @Published private(set) var hasLoadedOnce = false
    @Published var isLoadingParticipants = false
    @Published var error: String?
    @Published var requestsSentTo: Set<UUID> = []
    @Published var contactUserIds: Set<UUID> = []
    @Published private(set) var connectionStatuses: [UUID: ConnectionStatusState] = [:]
    @Published var currentUserId: UUID?
    @Published var isAdmin = false
    @Published var isRegistered = false
    @Published var isRegistering = false
    @Published var totalPages: Int = 0
    private let service = AppNetworking.shared
    private let authService = AppNetworking.auth
    private var participantFilterTask: Task<Void, Never>?
    private var loadingStatuses: Set<UUID> = []

    func loadData(appointmentId: UUID, page: Int) async {
        isLoading = true
        error = nil
        defer {
            isLoading = false
            hasLoadedOnce = true
        }

        let participantsTask = Task(priority: .userInitiated) {
            try await fetchParticipants(
                appointmentId: appointmentId,
                filterTags: participantFilterTags,
                page: page
            )
        }
        async let admin = fetchAdminRole(appointmentId: appointmentId)
        async let profile = fetchCurrentUserProfile(appointmentId: appointmentId)
        async let contacts = fetchContactUserIds()

        let loadedParticipants: [User]
        do {
            (loadedParticipants, totalPages) = try await participantsTask.value
        } catch {
            loadedParticipants = []
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }

        let snapshot = await DetailLoadSnapshot(
            isAdmin: admin,
            profile: profile,
            contactUserIds: contacts,
            participants: loadedParticipants
        )

        apply(snapshot)

        if snapshot.isAdmin, let statistics = await fetchStatistics(appointmentId: appointmentId) {
            stats = statistics
        }
    }

    func scheduleParticipantFilter(_ tags: [String], appointmentId: UUID, page: Int) {
        participantFilterTags = tags
        participantFilterTask?.cancel()
        participantFilterTask = Task(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await reloadParticipants(appointmentId: appointmentId, filterTags: tags, page: page)
        }
    }

    func registerForAppointment(appointmentId: UUID, tags: Set<Tag>) async {
        guard !tags.isEmpty else {
            error = "Выберите хотя бы один тег"
            return
        }

        isRegistering = true
        error = nil
        defer { isRegistering = false }

        var didRegister = false
        do {
            try await performRegistration(appointmentId: appointmentId)
            didRegister = true
            try await updateMyTags(appointmentId: appointmentId, tags: tags)
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .joinAppointment)
        }

        if didRegister {
            isRegistered = true
            await reloadParticipants(
                appointmentId: appointmentId,
                filterTags: participantFilterTags,
                page: 0
            )
        }
    }

    func sendConnectionRequest(toUserId: UUID, appointmentId: UUID) async {
        let dto = ConnectionRequestCreateDTO(toUserId: toUserId, appointmentId: appointmentId)
        let resource = Resource<ConnectionStatusDTO, SendConnectionRequestEndpoint>(
            request: SendConnectionRequestEndpoint(dto: dto)
        )
        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            let status = ConnectionStatusState(status: response.status, requestId: response.id)
            connectionStatuses[toUserId] = status
            requestsSentTo.insert(toUserId)
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }
    }

    func applyConnectionAccepted(with userId: UUID) {
        connectionStatuses[userId] = .contacts
        contactUserIds.insert(userId)
    }

    func applyConnectionDeclined(with userId: UUID) {
        connectionStatuses[userId] = .declined(requestId: nil)
    }

    func loadConnectionStatus(for user: User) async {
        guard let userId = user.id else { return }
        if let currentUserId, currentUserId == userId { return }
        if connectionStatuses[userId] != nil { return }
        if loadingStatuses.contains(userId) { return }

        loadingStatuses.insert(userId)
        defer { loadingStatuses.remove(userId) }

        let resource = Resource<UserConnectionStatusDTO, GetUserConnectionStatusRequest>(
            request: GetUserConnectionStatusRequest(
                userId: userId,
                username: nil
            ),
        )
        do {
            let dto = try await NetworkTask.fetch(service, resource: resource)
            connectionStatuses[userId] = ConnectionStatusState(
                status: dto.status,
                requestId: dto.requestId
            )
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }
    }

    // MARK: - Private

    private struct DetailLoadSnapshot {
        let isAdmin: Bool
        let profile: (userId: UUID?, isRegistered: Bool)?
        let contactUserIds: Set<UUID>
        let participants: [User]
    }

    private func apply(_ snapshot: DetailLoadSnapshot) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isAdmin = snapshot.isAdmin
            if let profile = snapshot.profile {
                currentUserId = profile.userId
                isRegistered = profile.isRegistered
            }
            contactUserIds = snapshot.contactUserIds
            participants = snapshot.participants
        }
    }

    private func reloadParticipants(appointmentId: UUID, filterTags: [String], page: Int) async {
        isLoadingParticipants = true
        defer { isLoadingParticipants = false }

        do {
            (participants, totalPages) = try await fetchParticipants(
                appointmentId: appointmentId,
                filterTags: filterTags,
                page: page
            )
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }
    }

    private func fetchAdminRole(appointmentId: UUID) async -> Bool {
        let resource = Resource<AppointmentRoleDTO, GetAppointmentRoleRequest>(
            request: GetAppointmentRoleRequest(appointmentId: appointmentId)
        )
        return (try? await NetworkTask.fetch(service, resource: resource))?.isAdmin ?? false
    }

    private func performRegistration(appointmentId: UUID) async throws {
        let resource = Resource<UserResponseDTO, RegisterForAppointmentRequest>(
            request: RegisterForAppointmentRequest(appointmentId: appointmentId),
        )
        _ = try await NetworkTask.fetch(service, resource: resource)
    }

    private func updateMyTags(appointmentId: UUID, tags: Set<Tag>) async throws {
        let dto = AppointmentTagsUpdateDTO(tags: tags.map(\.apiValue))
        let resource = Resource<Void, UpdateMyAppointmentTagsRequest>(
            request: UpdateMyAppointmentTagsRequest(
                appointmentId: appointmentId,
                dto: dto
            )
        )
        _ = try await NetworkTask.fetch(service, resource: resource)
    }

    private func fetchCurrentUserProfile(appointmentId: UUID) async -> (userId: UUID?, isRegistered: Bool)? {
        let resource = Resource<UserResponseDTO, GetMyProfileRequest>(
            request: GetMyProfileRequest(),
        )
        guard let profile = try? await NetworkTask.fetch(authService, resource: resource) else {
            return nil
        }
        let userId = UUID(uuidString: profile.id)
        let registered = profile.eventId?
            .lowercased() == appointmentId.uuidString.lowercased()
        return (userId, registered)
    }

    private func fetchContactUserIds() async -> Set<UUID> {
        let resource = Resource<[ContactDTO], GetContactsRequest>(
            request: GetContactsRequest()
        )
        guard let dtos = try? await NetworkTask.fetch(service, resource: resource) else {
            return []
        }
        return Set(dtos.map(\.id))
    }

    private func fetchParticipants(
        appointmentId: UUID,
        filterTags: [String],
        page: Int
    ) async throws -> ([User], Int) {
        let tagValues = filterTags.sorted()
        let resource = Resource<AppointmentsParcipiantsPagginatetDTO, GetAppointmentParticipantsRequest>(
            request: GetAppointmentParticipantsRequest(
                appointmentId: appointmentId,
                filterTags: tagValues,
                page: page
            )
        )
        let dtos = try await NetworkTask.fetch(service, resource: resource)

        return (dtos.items.map { $0.toUser() }, dtos.totalPages)
    }

    private func fetchStatistics(appointmentId: UUID) async -> AppointmentStats? {
        let resource = Resource<AppointmentStatsDTO, GetAppointmentStatsRequest>(
            request: GetAppointmentStatsRequest(appointmentId: appointmentId)
        )
        return (try? await NetworkTask.fetch(service, resource: resource))?.toStats()
    }
}
