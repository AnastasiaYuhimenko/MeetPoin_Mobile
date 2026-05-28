//
//  UserResponseDTO.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 28.05.2026.
//


struct UserResponseDTO: Decodable {
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

struct UserEventDTO: Decodable {
    let id: UUID
    let name: String
    let date: Date
    let description: String
    let tags: [String]
}

struct UserProfileDTO: Decodable {
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

struct UserUpdateDTO: Encodable {
    let name: String?
    let position: String
    let tags: [String]
    let about: String?
    let telegram: String?
    let email: String?
}

struct LoginResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct UsernameCheckResponseDTO: Decodable {
    let isAvailable: Bool
}