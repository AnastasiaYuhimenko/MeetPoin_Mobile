//
//  CreateEventViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Combine

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

    private let service = URLService.api

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !eventDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedTags.isEmpty
            && date > Date()
    }

    var customSelectedTags: [Tag] {
        selectedTags
            .filter { !$0.isPredefined }
            .sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
    }

    var canAddCustomTag: Bool {
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
            decoder: .api
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
            errorMessage = friendlyMessage(for: error)
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
        guard let tag = normalizedCustomTag else { return }
        selectedTags.insert(tag)
        customTagInput = ""
    }

    func removeCustomTag(_ tag: Tag) {
        selectedTags.remove(tag)
    }

    // MARK: - Helpers

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

    private func friendlyMessage(for error: Error) -> String {
        if let serviceError = error as? URLServiceError {
            switch serviceError {
            case .badStatusCode(let code, let data):
                let detail = parseServerDetail(from: data)
                switch code {
                case 400: return detail ?? "Проверьте теги: используйте короткие названия без спецсимволов"
                case 401: return detail ?? "Войдите, чтобы создавать мероприятия"
                case 422: return detail ?? "Проверьте введённые данные"
                case 500: return "Внутренняя ошибка сервера (500)\(detail.map { ": \($0)" } ?? "")"
                case 502, 503, 504: return "Сервис временно недоступен"
                default:  return detail.map { "Ошибка \(code): \($0)" } ?? "Ошибка сервера (\(code))"
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
