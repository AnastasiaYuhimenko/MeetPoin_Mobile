//
//  AppointmentResponse.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 28.05.2026.
//

import Foundation

struct AppointmentDTO: Decodable, Sendable {
    let id: UUID
    let title: String
    let date: Date
    let description: String
    let tags: [String]
    let participantsCount: Int
    let isParticipant: Bool
    let isAdmin: Bool
}

struct PagginatedAnswerAppointmentsDTO: Decodable, Sendable {
    let items: [AppointmentDTO]
    let totalPages: Int
}

struct AppointmentParticipantDTO: Decodable, Sendable {
    let id: UUID
    let name: String?
    let userName: String
    let position: String
    let tags: [String]
    let isAdmin: Bool
    let about: String?
    let telegram: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userName
        case position
        case tags
        case isAdmin
        case isOrganizer
        case role
        case about
        case telegram
        case email
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        userName = try container.decode(String.self, forKey: .userName)
        position = try container.decode(String.self, forKey: .position)
        tags = try container.decode([String].self, forKey: .tags)
        about = try container.decodeIfPresent(String.self, forKey: .about)
        telegram = try container.decodeIfPresent(String.self, forKey: .telegram)
        email = try container.decodeIfPresent(String.self, forKey: .email)

        if let flag = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) {
            isAdmin = flag
        } else if let flag = try container.decodeIfPresent(Bool.self, forKey: .isOrganizer) {
            isAdmin = flag
        } else if let role = try container.decodeIfPresent(String.self, forKey: .role) {
            isAdmin = role.lowercased() == "organizer" || role.lowercased() == "admin"
        } else {
            isAdmin = false
        }
    }
}

struct AppointmentsParcipiantsPagginatetDTO: Decodable, Sendable {
    let totalPages: Int
    let items: [AppointmentParticipantDTO]
}

struct AppointmentRoleDTO: Decodable, Sendable {
    let isAdmin: Bool
}

struct AppointmentStatsDTO: Decodable, Sendable {
    let registeredCount: Int
    let requestsSent: Int
    let requestsAccepted: Int
    let acquaintancesMade: Int
}

struct IncomingConnectionDTO: Decodable, Sendable {
    let id: UUID
    let fromUser: AppointmentParticipantDTO
    let appointmentId: UUID
    let createdAt: Date
}

struct ContactDTO: Decodable, Sendable {
    let id: UUID
    let name: String?
    let userName: String
    let position: String
    let tags: [String]
    let telegram: String?
    let email: String?
    let about: String?
}

struct ConnectionStatusDTO: Decodable, Sendable{
    let id: UUID
    let status: String
}

struct UserConnectionStatusDTO: Decodable, Sendable {
    let userId: UUID
    let name: String?
    let userName: String
    let status: String
    let requestId: UUID?
    let appointmentId: UUID?
}

struct EventResponseDTO: Decodable, Sendable {
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

struct TagsRespounseDTO: Decodable, Sendable {
    let tags: [String]
}

extension AppointmentDTO {
    func toAppointment(
    ) -> Appointment {
        return Appointment(
            id: id,
            title: title,
            date: date,
            description: description,
            tags: tags.compactMap { Tag(apiValue: $0) },
            participantsCount: participantsCount,
            isParticipating: isParticipant,
            isAdmin: isAdmin,
            allTags: tags
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
            telegram: telegram,
            email: email,
            about: about,
            isEventOrganizer: isAdmin
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
            about: about
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
