//
//  AuthEndpoint.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation

// MARK: - Base URL

extension URLService {
    static let auth = URLService(
        baseURL: URL(string: "http://111.88.144.41:8000/api/v1")!,
        retryConfiguration: RetryConfiguration(
            maxAttempts: 1,
            initialDelay: 0,
            multiplier: 1,
            maxDelay: 0
        )
    )
}

// MARK: - Response DTOs

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

// MARK: - Request DTOs

struct UserCreateDTO: Encodable {
    let name: String?
    let userName: String
    let position: String
    let password: String
    let tags: [String]
    let about: String?
    let telegram: String?
    let email: String?
}

// MARK: - Endpoints

struct CheckUsernameRequest: Requestable {
    let username: String
    var path: String { "/check-username" }
    var parameters: [URLQueryItem] { [URLQueryItem(name: "username", value: username)] }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct RegisterRequest: Requestable {
    typealias Body = UserCreateDTO
    let userCreate: UserCreateDTO
    var method: HTTPMethod { .POST }
    var path: String { "/register" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
    var body: UserCreateDTO? { userCreate }
}

struct LoginRequest: Requestable {
    let username: String
    let password: String
    var method: HTTPMethod { .POST }
    var path: String { "/login" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
    var formEncodedBody: [String: String]? {
        ["username": username, "password": password]
    }
}

struct GetMyProfileRequest: Requestable {
    var path: String { "/me" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
}

struct UpdateMyProfileRequest: Requestable {
    typealias Body = UserUpdateDTO
    let dto: UserUpdateDTO
    var method: HTTPMethod { .PATCH }
    var path: String { "/me" }
    var headers: [HTTPHeaderKey: String] { URLService.bearerHeaders }
    var body: UserUpdateDTO? { dto }
}
