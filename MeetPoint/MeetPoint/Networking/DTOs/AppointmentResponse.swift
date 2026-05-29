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
