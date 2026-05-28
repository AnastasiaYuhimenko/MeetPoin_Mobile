//
//  ConnectionRequestCreateDTO.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 28.05.2026.
//



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