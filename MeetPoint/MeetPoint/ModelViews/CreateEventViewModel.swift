//
//  CreateEventViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Combine
import Networking

struct CreatedEvent: Identifiable, Hashable {
    let id: UUID
    let name: String
    let date: Date
    let description: String
    let tags: [Tag]
    let qrUrl: String?
    let adminToken: String?
}

@MainActor
final class CreateEventViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var date: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @Published var eventDescription: String = ""
    @Published var selectedTags: Set<Tag> = []
    @Published var customTagInput: String = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdEvent: CreatedEvent?

    private let service = AppNetworking.shared

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !eventDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (TagSelectionLimits.minimum...TagSelectionLimits.maximum).contains(selectedTags.count)
            && date > Date()
    }

    var isAtTagMaximum: Bool {
        selectedTags.count >= TagSelectionLimits.maximum
    }

    var customSelectedTags: [Tag] {
        selectedTags
            .filter { !$0.isPredefined }
            .sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
    }

    var canAddCustomTag: Bool {
        guard !isAtTagMaximum else { return false }
        guard let tag = normalizedCustomTag else { return false }
        return !selectedTags.contains(tag)
    }

    func createEvent() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let dto = EventCreateDTO(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            description: eventDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: selectedTags.map(\.apiValue).sorted()
        )

        let resource = Resource<EventResponseDTO, CreateEventRequest>(
            request: CreateEventRequest(dto: dto),
        )

        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            createdEvent = CreatedEvent(
                id: response.id,
                name: response.name,
                date: response.date,
                description: response.description,
                tags: response.tags.compactMap { Tag(apiValue: $0) },
                qrUrl: response.qrUrl,
                adminToken: response.adminToken
            )
        } catch {
            errorMessage = UserFacingNetworkMessage.message(for: error, context: .createEvent)
        }
    }

    func reset() {
        name = ""
        date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        eventDescription = ""
        selectedTags = []
        customTagInput = ""
        createdEvent = nil
        errorMessage = nil
    }

    func addCustomTag() {
        guard !isAtTagMaximum, let tag = normalizedCustomTag else { return }
        selectedTags.insert(tag)
        customTagInput = ""
    }

    func removeCustomTag(_ tag: Tag) {
        selectedTags.remove(tag)
    }

    private var normalizedCustomTag: Tag? {
        let words = customTagInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return nil }
        return Tag(apiValue: words.joined(separator: "-"))
    }

}
