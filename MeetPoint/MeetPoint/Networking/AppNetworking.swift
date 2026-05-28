//
//  APIConfiguration.swift
//  MeetPoint
//

import Foundation
import Networking

enum AppNetworking {
    static let enviroment: NetworkEnvironment = {
        return try! NetworkEnvironment(scheme: "http", host: "192.168.1.101", apiPort: 8000, webPort: 80)
    }()
    
    
    static let auth = URLService(environment: enviroment, retryConfiguration: RetryConfiguration(maxAttempts: 1, initialDelay: 0, multiplier: 1, maxDelay: 0))
    
    static let shared = URLService(environment: enviroment)

    static let accessTokenProvider = UserDefaultsAccessTokenProvider()

    static var bearerHeaders: [HTTPHeaderKey: String] {
        accessTokenProvider.bearerHeaders
    }
    
    static func eventShareLink(for eventId: UUID) -> String {
        enviroment.webBaseURL!
            .appendingPathComponent("events")
            .appendingPathComponent(eventId.uuidString.lowercased())
            .absoluteString
    }
    
}
