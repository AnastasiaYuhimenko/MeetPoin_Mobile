//
//  AppointmentRequest.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 28.05.2026.
//

import Foundation

struct ConnectionRequestCreateDTO: Encodable, Sendable {
    let toUserId: UUID
    let appointmentId: UUID
}

struct EventCreateDTO: Encodable, Sendable {
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

struct AppointmentUpdateDTO: Encodable, Sendable {
    let title: String
    let date: Date
    let description: String
    let tags: [String]
}
