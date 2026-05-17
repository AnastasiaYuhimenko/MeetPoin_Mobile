//
//  EditAppointmentViewModel.swift
//  MeetPoint
//

import Foundation
import Combine

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

    private let service = URLService.api

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
            && !selectedTags.isEmpty
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
            request: UpdateAppointmentRequest(appointmentId: appointmentId, dto: dto),
            decoder: .api
        )

        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            let appointment = response.toAppointment()
            apply(appointment)
            storeSnapshot()
            return appointment
        } catch {
            errorMessage = friendlyMessage(for: error)
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

    private func friendlyMessage(for error: Error) -> String {
        if let serviceError = error as? URLServiceError {
            switch serviceError {
            case .badStatusCode(let code, let data):
                let detail = parseServerDetail(from: data)
                switch code {
                case 401: return detail ?? "Нет доступа к редактированию"
                case 403: return detail ?? "Только организатор может изменять мероприятие"
                case 422: return detail ?? "Проверьте введённые данные"
                default:
                    return detail.map { "Ошибка \(code): \($0)" } ?? "Ошибка сервера (\(code))"
                }
            case .invalidURL:
                return "Ошибка конфигурации приложения"
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed: return "Нет интернет-соединения"
            case .timedOut: return "Превышено время ожидания"
            case .cannotConnectToHost, .cannotFindHost: return "Не удаётся подключиться к серверу"
            default: break
            }
        }

        return error.localizedDescription
    }

    private func parseServerDetail(from data: Data) -> String? {
        struct Envelope: Decodable {
            let detail: RawDetail
            enum RawDetail: Decodable {
                case text(String)
                case list([Item])
                struct Item: Decodable { let msg: String }
                init(from decoder: Decoder) throws {
                    let c = try decoder.singleValueContainer()
                    if let s = try? c.decode(String.self) { self = .text(s); return }
                    if let a = try? c.decode([Item].self) { self = .list(a); return }
                    throw DecodingError.typeMismatch(
                        RawDetail.self,
                        .init(codingPath: decoder.codingPath, debugDescription: "unexpected detail type")
                    )
                }
                var message: String {
                    switch self {
                    case .text(let s): return s
                    case .list(let items): return items.map(\.msg).joined(separator: "\n")
                    }
                }
            }
        }
        return (try? JSONDecoder().decode(Envelope.self, from: data))?.detail.message
    }
}

private struct EditSnapshot: Equatable {
    let name: String
    let date: Date
    let description: String
    let tags: Set<Tag>
}
