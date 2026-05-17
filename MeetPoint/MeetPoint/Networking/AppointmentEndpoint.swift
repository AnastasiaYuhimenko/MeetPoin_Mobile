//
//  AppointmentEndpoint.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation

// MARK: - Shared API service

extension URLService {
    static let api = URLService(
        baseURL: URL(string: "http://111.88.144.41:8000")!,
        retryConfiguration: .default,
        encoder: .api
    )

    static let webBaseURL = URL(string: "http://111.88.144.41:80")!

    static func eventShareLink(for eventId: UUID) -> String {
        webBaseURL
            .appendingPathComponent("events")
            .appendingPathComponent(eventId.uuidString.lowercased())
            .absoluteString
    }

    static var storedToken: String? {
        UserDefaults.standard.string(forKey: "accessToken")
    }

    static var bearerHeaders: [HTTPHeaderKey: String] {
        guard let token = storedToken else { return [:] }
        return [.authorization: "Bearer \(token)"]
    }
}

// MARK: - JSON Decoder with ISO 8601 dates

extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
        ]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            for format in formats {
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = format
                if let date = f.date(from: string) { return date }
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse date: \(string)"
            )
        }
        return decoder
    }
}

// MARK: - JSON Encoder with ISO 8601 dates

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }
}

// MARK: - Response DTOs

struct AppointmentDTO: Decodable {
    let id: UUID
    let title: String
    let date: Date
    let description: String
    let tags: [String]
    let participantsCount: Int
}

struct AppointmentParticipantDTO: Decodable {
    let id: UUID
    let name: String?
    let userName: String
    let position: String
    let tags: [String]
}

struct AppointmentRoleDTO: Decodable {
    let isAdmin: Bool
}

struct AppointmentStatsDTO: Decodable {
    let registeredCount: Int
    let requestsSent: Int
    let requestsAccepted: Int
    let acquaintancesMade: Int
}

struct IncomingConnectionDTO: Decodable {
    let id: UUID
    let fromUser: AppointmentParticipantDTO
    let appointmentId: UUID
    let createdAt: Date
}

struct ContactDTO: Decodable {
    let id: UUID
    let name: String?
    let userName: String
    let position: String
    let tags: [String]
    let telegram: String?
    let email: String?
}

struct ConnectionStatusDTO: Decodable {
    let id: UUID
    let status: String
}

struct UserConnectionStatusDTO: Decodable {
    let userId: UUID
    let name: String?
    let userName: String
    let status: String
    let requestId: UUID?
    let appointmentId: UUID?
}

struct EventResponseDTO: Decodable {
    let id: UUID
    let name: String
    let date: Date
    let description: String
    let tags: [String]
    let qrUrl: String?
    let adminToken: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name = "title"
        case date
        case description
        case tags
        case qrUrl = "qr_url"
        case adminToken = "admin_token"
    }
}

// MARK: - Request DTOs

struct ConnectionRequestCreateDTO: Encodable {
    let toUserId: UUID
    let appointmentId: UUID
}

struct EventCreateDTO: Encodable {
    let name: String
    let date: Date
    let description: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case name = "title"
        case date
        case description
        case tags
    }
}

struct AppointmentUpdateDTO: Encodable {
    let title: String
    let date: Date
    let description: String
    let tags: [String]
}

// MARK: - DTO → Domain mapping

extension AppointmentDTO {
    func toAppointment(
        isParticipating: Bool = false,
        isAdmin: Bool = false
    ) -> Appointment {
        Appointment(
            id: id,
            title: title,
            date: date,
            description: description,
            tags: tags.compactMap { Tag(apiValue: $0) },
            participantsCount: participantsCount,
            isParticipating: isParticipating,
            isAdmin: isAdmin
        )
    }
}

extension AppointmentParticipantDTO {
    func toUser() -> User {
        let pos = MeetPoint.position(rawValue: self.position) ?? .other
        return User(
            id: id,
            name: name,
            userName: userName,
            position: pos,
            password: "",
            tags: tags.compactMap { Tag(apiValue: $0) },
            telegram: nil,
            email: nil,
            about: nil
        )
    }
}

extension ContactDTO {
    func toUser() -> User {
        let pos = MeetPoint.position(rawValue: self.position) ?? .other
        return User(
            id: id,
            name: name,
            userName: userName,
            position: pos,
            password: "",
            tags: tags.compactMap { Tag(apiValue: $0) },
            telegram: telegram,
            email: email,
            about: nil
        )
    }
}

extension AppointmentStatsDTO {
    func toStats() -> AppointmentStats {
        AppointmentStats(
            registeredCount: registeredCount,
            requestsSent: requestsSent,
            requestsAccepted: requestsAccepted,
            acquaintancesMade: acquaintancesMade
        )
    }
}

// MARK: - Endpoints: Appointments

struct ListAppointmentsRequest: Requestable {
    var path: String { "/appointments" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct ListMyCreatedAppointmentsRequest: Requestable {
    var path: String { "/appointments/my-created" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct GetAppointmentRequest: Requestable {
    let appointmentId: UUID
    var path: String { "/appointments/\(appointmentId)" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct UpdateAppointmentRequest: Requestable {
    typealias Body = AppointmentUpdateDTO
    let appointmentId: UUID
    let dto: AppointmentUpdateDTO
    var method: HTTPMethod { .PATCH }
    var path: String { "/appointments/\(appointmentId)" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
    var body: AppointmentUpdateDTO? { dto }
}

struct GetAppointmentRoleRequest: Requestable {
    let appointmentId: UUID
    var path: String { "/appointments/\(appointmentId)/my-role" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct GetAppointmentParticipantsRequest: Requestable {
    let appointmentId: UUID
    /// Пустой массив — без фильтра, все участники.
    let filterTags: [String]

    var path: String { "/appointments/\(appointmentId)/participants" }
    var parameters: [URLQueryItem] {
        filterTags.map { URLQueryItem(name: "tags", value: $0) }
    }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct GetAppointmentStatsRequest: Requestable {
    let appointmentId: UUID
    var path: String { "/appointments/\(appointmentId)/stats" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct RegisterForAppointmentRequest: Requestable {
    let appointmentId: UUID
    var method: HTTPMethod { .POST }
    var path: String { "/appointments/\(appointmentId)/register" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct AppointmentTagsUpdateDTO: Encodable {
    let tags: [String]
}

struct UpdateMyAppointmentTagsRequest: Requestable {
    typealias Body = AppointmentTagsUpdateDTO
    let appointmentId: UUID
    let dto: AppointmentTagsUpdateDTO
    var method: HTTPMethod { .PUT }
    var path: String { "/appointments/\(appointmentId)/my-tags" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
    var body: AppointmentTagsUpdateDTO? { dto }
}

// MARK: - Endpoints: Connections

struct SendConnectionRequestEndpoint: Requestable {
    typealias Body = ConnectionRequestCreateDTO
    let dto: ConnectionRequestCreateDTO
    var method: HTTPMethod { .POST }
    var path: String { "/connections/request" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
    var body: ConnectionRequestCreateDTO? { dto }
}

struct GetIncomingRequestsEndpoint: Requestable {
    var path: String { "/connections/incoming" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct AcceptConnectionRequest: Requestable {
    let requestId: UUID
    var method: HTTPMethod { .POST }
    var path: String { "/connections/\(requestId)/accept" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct DeclineConnectionRequest: Requestable {
    let requestId: UUID
    var method: HTTPMethod { .POST }
    var path: String { "/connections/\(requestId)/decline" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct GetContactsRequest: Requestable {
    var path: String { "/connections/contacts" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct GetUserConnectionStatusRequest: Requestable {
    let userId: UUID?
    let username: String?

    var path: String { "/connections/status" }
    var parameters: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let userId {
            items.append(URLQueryItem(name: "userId", value: userId.uuidString))
        } else if let username {
            items.append(URLQueryItem(name: "username", value: username))
        }
        return items
    }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

// MARK: - Endpoints: Events

struct CreateEventRequest: Requestable {
    typealias Body = EventCreateDTO
    let dto: EventCreateDTO
    var method: HTTPMethod { .POST }
    var path: String { "/appointments" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
    var body: EventCreateDTO? { dto }
}
