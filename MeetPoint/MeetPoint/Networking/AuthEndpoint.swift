//
//  AuthEndpoint.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Networking

struct CheckUsernameRequest: Requestable {
    let username: String
    var path: String { "/check-username" }
    var parameters: [URLQueryItem] { [URLQueryItem(name: "username", value: username)] }
    var timeoutInterval: TimeInterval? { 15 }
}

struct RegisterRequest: Requestable {
    typealias Body = UserCreateDTO
    let userCreate: UserCreateDTO
    var method: HTTPMethod { .POST }
    var path: String { "/register" }
    var body: UserCreateDTO? { userCreate }
}

struct LoginRequest: Requestable {
    let username: String
    let password: String
    var method: HTTPMethod { .POST }
    var path: String { "/login" }
    var formEncodedBody: [String: String]? {
        ["username": username, "password": password]
    }
}

struct GetMyProfileRequest: Requestable {
    var path: String { "/me" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct UpdateMyProfileRequest: Requestable {
    typealias Body = UserUpdateDTO
    let dto: UserUpdateDTO
    var method: HTTPMethod { .PATCH }
    var path: String { "/me" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
    var body: UserUpdateDTO? { dto }
}
