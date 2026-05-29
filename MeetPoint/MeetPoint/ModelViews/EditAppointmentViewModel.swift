//
//  EditAppointmentViewModel.swift
//  MeetPoint
//

import Foundation
import Combine
import Networking

@MainActor
final class EditAppointmentViewModel: ObservableObject {
    @Published var name = ""
    @Published var date = Date()
    @Published var eventDescription = ""
    @Published var selectedTags: Set<Tag> = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let appointmentId: UUID
    private var savedSnapshot: EditSnapshot?

    private let service = AppNetworking.shared

    init(appointment: Appointment) {
        appointmentId = appointment.id
        apply(appointment)
        storeSnapshot()
    }

    var hasChanges: Bool {
        guard let saved = savedSnapshot else { return false }
        return name.trimmingCharacters(in: .whitespacesAndNewlines) != saved.name
            || abs(date.timeIntervalSince(saved.date)) > 1
            || eventDescription.trimmingCharacters(in: .whitespacesAndNewlines) != saved.description
            || selectedTags != saved.tags
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !eventDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (TagSelectionLimits.minimum...TagSelectionLimits.maximum).contains(selectedTags.count)
    }

    var isAtTagMaximum: Bool {
        selectedTags.count >= TagSelectionLimits.maximum
    }

    var canSave: Bool {
        hasChanges && isFormValid && !isLoading
    }

    func save() async -> Appointment? {
        guard canSave else { return nil }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let dto = AppointmentUpdateDTO(
            title: name.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            description: eventDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: selectedTags.map(\.apiValue).sorted()
        )

        let resource = Resource<AppointmentDTO, UpdateAppointmentRequest>(
            request: UpdateAppointmentRequest(appointmentId: appointmentId, dto: dto)
        )

        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            let appointment = response.toAppointment()
            apply(appointment)
            storeSnapshot()
            return appointment
        } catch {
            errorMessage = UserFacingNetworkMessage.message(for: error, context: .editAppointment)
            return nil
        }
    }

    private func apply(_ appointment: Appointment) {
        name = appointment.title
        date = appointment.date
        eventDescription = appointment.description
        selectedTags = Set(appointment.tags)
    }

    private func storeSnapshot() {
        savedSnapshot = EditSnapshot(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            description: eventDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: selectedTags
        )
    }

}

private struct EditSnapshot: Equatable {
    let name: String
    let date: Date
    let description: String
    let tags: Set<Tag>
}
