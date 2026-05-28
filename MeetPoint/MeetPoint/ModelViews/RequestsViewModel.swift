//
//  RequestsViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Combine
import SwiftUI
import Networking

struct IncomingRequest: Identifiable {
    let id: UUID
    let fromUser: User
    let appointmentId: UUID
}

@MainActor
final class RequestsViewModel: ObservableObject {
    @Published var requests: [IncomingRequest] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = AppNetworking.shared
    private var hasLoaded = false

    func loadRequests(force: Bool = false) async {
        if hasLoaded && !force { return }
        if isLoading { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let resource = Resource<[IncomingConnectionDTO], GetIncomingRequestsEndpoint>(
            request: GetIncomingRequestsEndpoint(),
        )
        do {
            let dtos = try await NetworkTask.fetch(service, resource: resource)
            requests = dtos.map {
                IncomingRequest(
                    id: $0.id,
                    fromUser: $0.fromUser.toUser(),
                    appointmentId: $0.appointmentId
                )
            }
            hasLoaded = true
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }
    }

    func acceptRequest(_ requestId: UUID) async {
        let resource = Resource<ConnectionStatusDTO, AcceptConnectionRequest>(
            request: AcceptConnectionRequest(requestId: requestId)
        )
        do {
            _ = try await NetworkTask.fetch(service, resource: resource)
            withAnimation { requests.removeAll { $0.id == requestId } }
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }
    }

    func declineRequest(_ requestId: UUID) async {
        let resource = Resource<ConnectionStatusDTO, DeclineConnectionRequest>(
            request: DeclineConnectionRequest(requestId: requestId)
        )
        do {
            _ = try await NetworkTask.fetch(service, resource: resource)
            withAnimation { requests.removeAll { $0.id == requestId } }
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }
    }
}
