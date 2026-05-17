//
//  DeepLinkRouter.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Combine

/// Принимает URL вида:
///   meetpoint://event/<uuid>
///   https://<host>/event/<uuid>
///   https://<host>/appointments/<uuid>
@MainActor
final class DeepLinkRouter: ObservableObject {

    /// id мероприятия, на которое нужно открыть детальный экран
    @Published var pendingAppointmentId: UUID?

    /// Текст ошибки, если ссылку не удалось разобрать
    @Published var error: String?

    func handle(url: URL) {
        guard let id = extractAppointmentId(from: url) else {
            error = "Ссылка не распознана как мероприятие"
            return
        }
        pendingAppointmentId = id
    }

    func clearAppointment() {
        pendingAppointmentId = nil
    }

    // MARK: - Parsing

    private func extractAppointmentId(from url: URL) -> UUID? {
        let scheme = url.scheme?.lowercased() ?? ""

        let segments = url.pathComponents.filter { $0 != "/" }
        let host = url.host?.lowercased()

        switch scheme {
        case "meetpoint":
            // meetpoint://event/<id>  -> host = "event", path = "/<id>"
            if let last = segments.last, let id = UUID(uuidString: last) {
                return id
            }
            if let host, let id = UUID(uuidString: host), segments.isEmpty {
                return id
            }
        case "https", "http":
            // https://example.com/event/<id> или /appointments/<id>
            let allowedPrefixes: Set<String> = ["event", "events", "appointment", "appointments"]
            for (index, segment) in segments.enumerated() {
                if allowedPrefixes.contains(segment.lowercased()),
                   index + 1 < segments.count,
                   let id = UUID(uuidString: segments[index + 1])
                {
                    return id
                }
            }
            if let last = segments.last, let id = UUID(uuidString: last) {
                return id
            }
        default:
            break
        }
        return nil
    }
}
