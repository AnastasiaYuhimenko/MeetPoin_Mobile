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

struct Tag: RawRepresentable, CaseIterable, Identifiable, Hashable {
    let rawValue: String

    static let frontend = Tag(rawValue: "frontend")
    static let backend = Tag(rawValue: "backend")
    static let mobile = Tag(rawValue: "mobile")
    static let ai = Tag(rawValue: "ai")
    static let fintech = Tag(rawValue: "fintech")
    static let career = Tag(rawValue: "career")
    static let analitic = Tag(rawValue: "analitic")
    static let startup = Tag(rawValue: "startup")

    static let allCases: [Tag] = [
        .frontend,
        .backend,
        .mobile,
        .ai,
        .fintech,
        .career,
        .analitic,
        .startup
    ]

    var id: String { apiValue.lowercased() }

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.apiValue.caseInsensitiveCompare(rhs.apiValue) == .orderedSame
    }
}

extension Tag {
    /// Значение, которое ожидает/возвращает сервер.
    var apiValue: String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased() == "analitic" {
            return "analytic"
        }
        return trimmed
    }

    var isPredefined: Bool {
        Self.allCases.contains(self)
    }

    init?(apiValue: String) {
        let trimmed = apiValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.lowercased()
        switch normalized {
        case "frontend": self = .frontend
        case "backend": self = .backend
        case "mobile": self = .mobile
        case "ai": self = .ai
        case "fintech": self = .fintech
        case "career": self = .career
        case "analytic", "analitic": self = .analitic
        case "startup": self = .startup
        default: self = Tag(rawValue: trimmed)
        }
    }
}

struct User: Identifiable {
    let id: UUID?
    /// Отображаемое имя с бэкенда (`name`), опционально при регистрации.
    let name: String?
    let userName: String
    let position: position
    let password: String
    let tags: [Tag]
    let telegram: String?
    let email: String?
    let about: String?

    /// Заголовок для UI: непустое `name`, иначе `userName`.
    var displayName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? userName : trimmed
    }
}

struct userDevelop {
    static let user = User(
        id: UUID(uuidString: "4448457c-caaf-4d90-afbc-fa76982b7955")!,
        name: "Анна",
        userName: "Name",
        position: position.designer,
        password: "Sequre-Password",
        tags: [.mobile, .ai, .analitic, .backend, .career, .fintech, .frontend, .startup],
        telegram: "telegram",
        email: "email",
        about: "Hello im dev person and im really cool, lets talk, sdjlkdsvlndsvlksdksdksdkse"
    )
}
