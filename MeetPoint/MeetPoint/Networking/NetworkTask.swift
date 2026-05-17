//
//  NetworkTask.swift
//  MeetPoint
//

import Foundation

/// Выполняет сетевой запрос и декодирование вне main actor.
enum NetworkTask {
    static func fetch<Response, Request: Requestable>(
        _ service: URLService,
        resource: Resource<Response, Request>,
        priority: TaskPriority = .userInitiated
    ) async throws -> Response {
        try await Task.detached(priority: priority) {
            try await service.dataTask(with: resource)
        }.value
    }
}
