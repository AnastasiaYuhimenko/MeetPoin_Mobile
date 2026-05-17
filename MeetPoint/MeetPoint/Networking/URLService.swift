//
//  URLService.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

struct HTTPHeaderKey: ExpressibleByStringLiteral, Hashable {
    let rawValue: String

    init(stringLiteral value: String) {
        rawValue = value
    }
}

extension HTTPHeaderKey {
    static let contentType = HTTPHeaderKey("Content-Type")
    static let accept = HTTPHeaderKey("Accept")
    static let authorization = HTTPHeaderKey("Authorization")
}

protocol Requestable {
    associatedtype Body: Encodable = EmptyRequestBody

    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: [URLQueryItem] { get }
    var headers: [HTTPHeaderKey: String] { get }
    var body: Body? { get }
    var formEncodedBody: [String: String]? { get }
    var timeoutInterval: TimeInterval? { get }

    func fullURL(baseURL: URL) -> URL?
}

extension Requestable {
    var method: HTTPMethod { .GET }
    var parameters: [URLQueryItem] { [] }
    var headers: [HTTPHeaderKey: String] { [:] }
    var body: EmptyRequestBody? { nil }
    var formEncodedBody: [String: String]? { nil }
    var timeoutInterval: TimeInterval? { nil }

    func fullURL(baseURL: URL) -> URL? {
        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            guard var components = URLComponents(url: absoluteURL, resolvingAgainstBaseURL: false) else {
                return absoluteURL
            }

            if !parameters.isEmpty {
                components.queryItems = parameters
            }

            return components.url
        }

        guard let url = URL(string: path, relativeTo: baseURL),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            return nil
        }

        if !parameters.isEmpty {
            components.queryItems = parameters
        }

        return components.url
    }
}

struct Resource<Response, Request: Requestable> {
    let request: Request
    let decode: (Data) throws -> Response
}

extension Resource where Response: Decodable {
    init(request: Request, decoder: JSONDecoder = JSONDecoder()) {
        self.init(request: request) { data in
            try decoder.decode(Response.self, from: data)
        }
    }
}

extension Resource where Response == Void {
    init(request: Request) {
        self.init(request: request) { _ in () }
    }
}

struct RetryConfiguration {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let multiplier: Double
    let maxDelay: TimeInterval

    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 0.5,
        multiplier: 2.0,
        maxDelay: 10.0
    )

    func delay(for attempt: Int) -> TimeInterval {
        min(initialDelay * pow(multiplier, Double(attempt)), maxDelay)
    }
}

/// Делегат сессии, который сохраняет заголовок `Authorization` при HTTP-редиректах.
/// По умолчанию `URLSession` срезает кастомные заголовки на редиректе, из-за чего
/// FastAPI-редирект с trailing slash превращает авторизованный запрос в анонимный
/// и сервер отвечает 401 «Not authenticated».
final class AuthorizationPreservingSessionDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        var redirected = request
        if redirected.value(forHTTPHeaderField: HTTPHeaderKey.authorization.rawValue) == nil,
           let originalAuth = task.originalRequest?.value(
                forHTTPHeaderField: HTTPHeaderKey.authorization.rawValue
           )
        {
            redirected.setValue(originalAuth, forHTTPHeaderField: HTTPHeaderKey.authorization.rawValue)
        }
        if let from = response.url?.absoluteString,
           let to = redirected.url?.absoluteString,
           from != to
        {
            NetworkLogger.logRedirect(from: from, to: to, statusCode: response.statusCode)
        }

        completionHandler(redirected)
    }
}

final class URLService: @unchecked Sendable {
    private let baseURL: URL
    private let urlSession: URLSession
    private let retryConfiguration: RetryConfiguration
    private let encoder: JSONEncoder

    /// Вызывается при получении 401 Unauthorized от любого запроса через этот сервис.
    /// Устанавливается снаружи (например, из AuthViewModel) для глобального перехвата истёкших сессий.
    var onUnauthorized: (@Sendable () -> Void)?

    init(
        baseURL: URL,
        urlSession: URLSession? = nil,
        retryConfiguration: RetryConfiguration = .default,
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        if let urlSession {
            self.urlSession = urlSession
        } else {
            self.urlSession = URLSession(
                configuration: .default,
                delegate: AuthorizationPreservingSessionDelegate(),
                delegateQueue: nil
            )
        }
        self.retryConfiguration = retryConfiguration
        self.encoder = encoder
    }

    func dataTask<Response, Request>(
        with resource: Resource<Response, Request>
    ) async throws -> Response {
        var lastError: Error?

        for attempt in 0 ..< retryConfiguration.maxAttempts {
            let startedAt = Date()
            let urlRequest: URLRequest

            do {
                urlRequest = try makeURLRequest(from: resource.request)
            } catch {
                NetworkLogger.logFailure(
                    error,
                    request: URLRequest(url: baseURL),
                    duration: 0,
                    willRetry: false,
                    nextAttempt: nil
                )
                throw error
            }

            NetworkLogger.logRequest(
                urlRequest,
                attempt: attempt,
                maxAttempts: retryConfiguration.maxAttempts
            )

            do {
                let (data, response) = try await urlSession.data(for: urlRequest)
                let duration = Date().timeIntervalSince(startedAt)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                guard (200 ..< 300).contains(httpResponse.statusCode) else {
                    if httpResponse.statusCode == 401 {
                        onUnauthorized?()
                    }
                    throw URLServiceError.badStatusCode(httpResponse.statusCode, data)
                }

                NetworkLogger.logResponse(httpResponse, data: data, duration: duration, request: urlRequest)

                do {
                    return try resource.decode(data)
                } catch {
                    NetworkLogger.logDecodeFailure(error, request: urlRequest, data: data)
                    throw error
                }
            } catch {
                if error is DecodingError {
                    throw error
                }

                lastError = error
                let duration = Date().timeIntervalSince(startedAt)
                let willRetry = isRetryable(error) && attempt < retryConfiguration.maxAttempts - 1

                NetworkLogger.logFailure(
                    error,
                    request: urlRequest,
                    duration: duration,
                    willRetry: willRetry,
                    nextAttempt: willRetry ? attempt + 2 : nil
                )

                guard willRetry else {
                    throw error
                }

                let delay = retryConfiguration.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    private func makeURLRequest<Request: Requestable>(from request: Request) throws -> URLRequest {
        guard let fullURL = request.fullURL(baseURL: baseURL) else {
            throw URLServiceError.invalidURL
        }

        var urlRequest = URLRequest(url: fullURL)
        urlRequest.httpMethod = request.method.rawValue

        if let timeout = request.timeoutInterval {
            urlRequest.timeoutInterval = timeout
        }

        for (key, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: key.rawValue)
        }

        if let formBody = request.formEncodedBody {
            let encoded = formBody
                .map { key, value -> String in
                    let encodedValue = value.addingPercentEncoding(
                        withAllowedCharacters: .urlQueryAllowed.subtracting(.init(charactersIn: "+&="))
                    ) ?? value
                    return "\(key)=\(encodedValue)"
                }
                .joined(separator: "&")
            urlRequest.httpBody = encoded.data(using: .utf8)
            if request.headers[.contentType] == nil {
                urlRequest.addValue(
                    "application/x-www-form-urlencoded",
                    forHTTPHeaderField: HTTPHeaderKey.contentType.rawValue
                )
            }
        } else if let body = request.body {
            urlRequest.httpBody = try encoder.encode(body)
            if request.headers[.contentType] == nil {
                urlRequest.addValue("application/json", forHTTPHeaderField: HTTPHeaderKey.contentType.rawValue)
            }
        }

        return urlRequest
    }

    private func isRetryable(_ error: Error) -> Bool {
        if let serviceError = error as? URLServiceError {
            return serviceError.isRetryable
        }

        guard let urlError = error as? URLError else {
            return false
        }

        let retryableCodes: [URLError.Code] = [
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet,
            .secureConnectionFailed,
            .dataNotAllowed
        ]

        return retryableCodes.contains(urlError.code)
    }
}

struct EmptyRequestBody: Encodable {}

enum URLServiceError: LocalizedError {
    case invalidURL
    case badStatusCode(Int, Data)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case let .badStatusCode(statusCode, data):
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            return "Request failed with status code \(statusCode): \(body)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .invalidURL:
            return false
        case let .badStatusCode(statusCode, _):
            return [408, 429, 500, 502, 503, 504].contains(statusCode)
        }
    }
}
