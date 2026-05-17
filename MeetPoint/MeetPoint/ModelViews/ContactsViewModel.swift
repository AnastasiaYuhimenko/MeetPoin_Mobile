//
//  ContactsViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Combine

@MainActor
final class ContactsViewModel: ObservableObject {
    @Published var contacts: [User] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = URLService.api
    private var hasLoaded = false

    func loadContacts(force: Bool = false) async {
        if hasLoaded && !force { return }
        if isLoading { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let resource = Resource<[ContactDTO], GetContactsRequest>(
            request: GetContactsRequest()
        )
        do {
            let dtos = try await NetworkTask.fetch(service, resource: resource)
            contacts = dtos.map { $0.toUser() }
            hasLoaded = true
        } catch {
            self.error = UserFacingNetworkMessage.message(for: error, context: .apiAction)
        }
    }
}
