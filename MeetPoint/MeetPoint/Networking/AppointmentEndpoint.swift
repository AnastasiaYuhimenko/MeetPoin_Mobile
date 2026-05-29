//
//  AppointmentEndpoint.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import Foundation
import Networking
// MARK: - Requestable stucts

struct ListAppointmentsRequest: Requestable {
    let page: Int
    let filtrTags: [String]
    let myRole: AppointmentOwnershipFilter?
    var path: String { "/appointments" }
    var parameters: [URLQueryItem] {
        var q = [URLQueryItem(name: "page", value: String(page))]
        if let myRole {
            q.append(URLQueryItem(name: "role", value: myRole.param))
        }
        if !filtrTags.isEmpty {
            q.append(makeURLQweryTags(tags: filtrTags))
        }
        return q
    }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct ListMyCreatedAppointmentsRequest: Requestable {
    let page: Int
    var path: String { "/appointments/my-created" }
    var parameters: [URLQueryItem] {
        [URLQueryItem(name: "page", value: String(page))]
    }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct GetAppointmentRequest: Requestable {
    let appointmentId: UUID
    var path: String { "/appointments/\(appointmentId)" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct UpdateAppointmentRequest: Requestable {
    typealias Body = AppointmentUpdateDTO
    let appointmentId: UUID
    let dto: AppointmentUpdateDTO
    var method: HTTPMethod { .PATCH }
    var path: String { "/appointments/\(appointmentId)" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
    var body: AppointmentUpdateDTO? { dto }
}

struct GetAppointmentRoleRequest: Requestable {
    let appointmentId: UUID
    var path: String { "/appointments/\(appointmentId)/my-role" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct GetAppointmentParticipantsRequest: Requestable {
    let appointmentId: UUID
    /// пустой массив — без фильтра, все участники.
    let filterTags: [String]
    let page: Int

    var path: String { "/appointments/\(appointmentId)/participants" }
    var parameters: [URLQueryItem] {
        var lst: [URLQueryItem] = []
        lst.append(URLQueryItem(name: "page", value: String(page)))
        if !filterTags.isEmpty {
            lst.append(makeURLQweryTags(tags: filterTags))
        }
        return lst
    }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct GetAppointmentStatsRequest: Requestable {
    let appointmentId: UUID
    var path: String { "/appointments/\(appointmentId)/stats" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct RegisterForAppointmentRequest: Requestable {
    let appointmentId: UUID
    var method: HTTPMethod { .POST }
    var path: String { "/appointments/\(appointmentId)/register" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct AppointmentTagsUpdateDTO: Encodable {
    let tags: [String]
}

struct UpdateMyAppointmentTagsRequest: Requestable {
    typealias Body = AppointmentTagsUpdateDTO
    let appointmentId: UUID
    let dto: AppointmentTagsUpdateDTO
    var method: HTTPMethod { .PUT }
    var path: String { "/appointments/\(appointmentId)/my-tags" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
    var body: AppointmentTagsUpdateDTO? { dto }
}

// MARK: - Requestable stucts, Connections

struct SendConnectionRequestEndpoint: Requestable {
    typealias Body = ConnectionRequestCreateDTO
    let dto: ConnectionRequestCreateDTO
    var method: HTTPMethod { .POST }
    var path: String { "/connections/request" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
    var body: ConnectionRequestCreateDTO? { dto }
}

struct GetIncomingRequestsEndpoint: Requestable {
    var path: String { "/connections/incoming" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct AcceptConnectionRequest: Requestable {
    let requestId: UUID
    var method: HTTPMethod { .POST }
    var path: String { "/connections/\(requestId)/accept" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct DeclineConnectionRequest: Requestable {
    let requestId: UUID
    var method: HTTPMethod { .POST }
    var path: String { "/connections/\(requestId)/decline" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct GetContactsRequest: Requestable {
    var path: String { "/connections/contacts" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

struct GetUserConnectionStatusRequest: Requestable {
    let userId: UUID?
    let username: String?

    var path: String { "/connections/status" }
    var parameters: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let userId {
            items.append(URLQueryItem(name: "userId", value: userId.uuidString))
        } else if let username {
            items.append(URLQueryItem(name: "username", value: username))
        }
        return items
    }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
}

// MARK: - Requestable stucts, Events

struct CreateEventRequest: Requestable {
    typealias Body = EventCreateDTO
    let dto: EventCreateDTO
    var method: HTTPMethod { .POST }
    var path: String { "/appointments" }
    var headers: [HTTPHeaderKey: String] { AppNetworking.bearerHeaders }
    var body: EventCreateDTO? { dto }
}

// сделает из списка тегов query параметр
private func makeURLQweryTags(tags: [String]) -> URLQueryItem {
    let s = tags.joined(separator: ",")
    return URLQueryItem(name: "tags", value: s)
}
