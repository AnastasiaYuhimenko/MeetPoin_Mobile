//
//  NetworkLogger.swift
//  MeetPoint
//

import Foundation
import os

enum NetworkLogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MeetPoint",
        category: "Networking"
    )

    private static let maxBodyLength = 4_096

    static func logRequest(_ request: URLRequest, attempt: Int, maxAttempts: Int) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<unknown url>"
        let attemptLabel = maxAttempts > 1 ? " (attempt \(attempt + 1)/\(maxAttempts))" : ""

        logger.info("\(method, privacy: .public) \(url, privacy: .public)\(attemptLabel, privacy: .public)")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("Headers: \(sanitizedHeaders(headers), privacy: .private)")
        }

        if let body = request.httpBody, !body.isEmpty {
            logger.debug("Body: \(formattedBody(body), privacy: .private)")
        }
    }

    static func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval,
        request: URLRequest
    ) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<unknown url>"
        let durationMs = Int(duration * 1_000)

        logger.info(
            "\(method, privacy: .public) \(url, privacy: .public) → \(response.statusCode, privacy: .public) (\(durationMs, privacy: .public)ms, \(data.count, privacy: .public) bytes)"
        )

        #if DEBUG
        if !data.isEmpty {
            logger.debug("Response: \(formattedBody(data), privacy: .private)")
        }
        #endif
    }

    static func logDecodeFailure(_ error: Error, request: URLRequest, data: Data) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<unknown url>"
        logger.error(
            "\(method, privacy: .public) \(url, privacy: .public) decode failed: \(error.localizedDescription, privacy: .public)"
        )
        #if DEBUG
        logger.debug("Response body: \(formattedBody(data), privacy: .private)")
        #endif
    }

    static func logRedirect(from: String, to: String, statusCode: Int) {
        logger.info(
            "Redirect \(statusCode, privacy: .public): \(from, privacy: .public) → \(to, privacy: .public)"
        )
    }

    static func logFailure(
        _ error: Error,
        request: URLRequest,
        duration: TimeInterval,
        willRetry: Bool,
        nextAttempt: Int?
    ) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<unknown url>"
        let durationMs = Int(duration * 1_000)

        if let serviceError = error as? URLServiceError,
           case let .badStatusCode(statusCode, data) = serviceError
        {
            logger.error(
                "\(method, privacy: .public) \(url, privacy: .public) → HTTP \(statusCode, privacy: .public) (\(durationMs, privacy: .public)ms): \(formattedBody(data), privacy: .private)"
            )
        } else {
            logger.error(
                "\(method, privacy: .public) \(url, privacy: .public) failed (\(durationMs, privacy: .public)ms): \(error.localizedDescription, privacy: .public)"
            )
        }

        if willRetry, let nextAttempt {
            logger.warning("Retrying \(url, privacy: .public), attempt \(nextAttempt, privacy: .public)")
        }
    }

    // MARK: - Helpers

    private static func sanitizedHeaders(_ headers: [String: String]) -> String {
        headers
            .map { key, value in
                if key.lowercased() == HTTPHeaderKey.authorization.rawValue.lowercased() {
                    return "\(key): \(redactedAuthorization(value))"
                }
                return "\(key): \(value)"
            }
            .sorted()
            .joined(separator: ", ")
    }

    private static func redactedAuthorization(_ value: String) -> String {
        if value.hasPrefix("Bearer ") {
            return "Bearer ***"
        }
        return "***"
    }

    private static func formattedBody(_ data: Data) -> String {
        guard let text = String(data: data, encoding: .utf8) else {
            return "<\(data.count) bytes, non-UTF8>"
        }

        if text.count <= maxBodyLength {
            return text
        }

        let index = text.index(text.startIndex, offsetBy: maxBodyLength)
        return String(text[..<index]) + "… [truncated]"
    }
}
