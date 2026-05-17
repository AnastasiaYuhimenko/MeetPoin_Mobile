//
//  Registration.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import Foundation
import Combine

enum position: String, CaseIterable, Identifiable {
    case frontend
    case backend
    case mobile
    case ml
    case product
    case analitic
    case other
    case designer
    
    var id: String { rawValue }
}

enum Tag: String, CaseIterable, Identifiable {
    case frontend
    case backend
    case mobile
    case ai
    case fintech
    case career
    case analitic
    case startup
    
    var id: String { rawValue }
}

extension Tag {
    /// Значение, которое ожидает/возвращает сервер.
    var apiValue: String {
        switch self {
        case .analitic:
            return "analytic"
        default:
            return rawValue
        }
    }

    init?(apiValue: String) {
        let normalized = apiValue.lowercased()
        switch normalized {
        case "frontend": self = .frontend
        case "backend": self = .backend
        case "mobile": self = .mobile
        case "ai": self = .ai
        case "fintech": self = .fintech
        case "career": self = .career
        case "analytic", "analitic": self = .analitic
        case "startup": self = .startup
        default: return nil
        }
    }
}

struct User: Identifiable {
    let id: UUID?
    let userName: String
    let position: position
    let password: String
    let tags: [Tag]
    let telegram: String?
    let email: String?
    let about: String?
}

struct userDevelop {
    static let user = User(id: UUID(uuidString: "4448457c-caaf-4d90-afbc-fa76982b7955")!, userName: "Name", position: position.designer, password: "Sequre-Password", tags: [.mobile, .ai, .analitic, .backend, .career, .fintech, .frontend, .startup], telegram: "telegram", email: "email", about: "Hello im dev person and im really cool, lets talk, sdjlkdsvlndsvlksdksdksdkse")
    
}
