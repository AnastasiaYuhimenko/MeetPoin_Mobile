//
//  AppointmentRequest.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 28.05.2026.
//

import Foundation

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
