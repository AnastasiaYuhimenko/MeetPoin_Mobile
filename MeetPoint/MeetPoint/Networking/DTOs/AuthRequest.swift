//
//  AuthRequest.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 28.05.2026.
//

struct UserCreateDTO: Encodable, Sendable {
    let name: String?
    let userName: String
    let position: String
    let password: String
    let tags: [String]
    let about: String?
    let telegram: String?
    let email: String?
}
