//
//  AuthResponse.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 28.05.2026.
//

import Foundation

struct UserResponseDTO: Decodable, Sendable {
    let id: String
    let name: String?
    let userName: String
    let position: String
    let tags: [String]
    let telegram: String?
    let email: String?
    let eventId: String?
    let about: String?
}

struct UserEventDTO: Decodable, Sendable {
    let id: UUID
    let name: String
    let date: Date
    let description: String
    let tags: [String]
}

struct UserProfileDTO: Decodable, Sendable {
    let id: String
    let name: String?
    let userName: String
    let position: String
    let tags: [String]
    let telegram: String?
    let email: String?
    let eventId: String?
    let about: String?
    let event: UserEventDTO?
}

struct UserUpdateDTO: Encodable, Sendable {
    let name: String?
    let position: String
    let tags: [String]
    let about: String?
    let telegram: String?
    let email: String?
}

struct LoginResponseDTO: Decodable, Sendable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct UsernameCheckResponseDTO: Decodable, Sendable {
    let isAvailable: Bool
}

extension UserResponseDTO {
    func toUser(merging fallback: User) -> User {
        User(
            id: UUID(uuidString: id) ?? fallback.id,
            name: name ?? fallback.name,
            userName: userName,
            position: MeetPoint.position(rawValue: position) ?? fallback.position,
            password: fallback.password,
            tags: tags.compactMap { Tag(apiValue: $0) },
            telegram: telegram ?? fallback.telegram,
            email: email ?? fallback.email,
            about: about ?? fallback.about,
            isEventOrganizer: fallback.isEventOrganizer
        )
    }
}

extension UserProfileDTO {
    func toUser(merging fallback: User) -> User {
        User(
            id: UUID(uuidString: id) ?? fallback.id,
            name: name ?? fallback.name,
            userName: userName,
            position: MeetPoint.position(rawValue: position) ?? fallback.position,
            password: fallback.password,
            tags: tags.compactMap { Tag(apiValue: $0) },
            telegram: telegram ?? fallback.telegram,
            email: email ?? fallback.email,
            about: about ?? fallback.about,
            isEventOrganizer: fallback.isEventOrganizer
        )
    }
}
