//
//  authViewModel.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    @Published var isUsernameAvailable: Bool?

    private let urlService = URLService.auth

    private(set) var currentUser: UserResponseDTO?

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "accessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "accessToken") }
    }

    init() {
        isLoggedIn = accessToken != nil
        urlService.onUnauthorized = { [weak self] in
            QoSRunner.fireAndForgetUtility {
                await MainActor.run { [weak self] in
                    self?.logout()
                }
            }
        }
    }

    // MARK: - Username availability

    func checkUsername(_ username: String) async {
        isUsernameAvailable = nil
        guard username.count >= 3 else { return }

        let resource = Resource<UsernameCheckResponseDTO, CheckUsernameRequest>(
            request: CheckUsernameRequest(username: username)
        )
        let service = urlService
        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            isUsernameAvailable = response.isAvailable
        } catch {
            isUsernameAvailable = nil
        }
    }

    // MARK: - Registration

    func register(user: User) async {
        isLoading = true
        errorMessage = nil

        let dto = UserCreateDTO(
            name: user.name,
            userName: user.userName,
            position: user.position.rawValue,
            password: user.password,
            tags: user.tags.map { $0.apiValue },
            about: user.about,
            telegram: user.telegram,
            email: user.email
        )

        let resource = Resource<UserResponseDTO, RegisterRequest>(
            request: RegisterRequest(userCreate: dto)
        )

        let service = urlService
        do {
            _ = try await NetworkTask.fetch(service, resource: resource)
            await auth(userName: user.userName, password: user.password)
        } catch {
            errorMessage = friendlyMessage(for: error)
            isLoading = false
        }
    }

    // MARK: - Login

    func auth(userName: String, password: String) async {
        isLoading = true
        errorMessage = nil

        let resource = Resource<LoginResponseDTO, LoginRequest>(
            request: LoginRequest(username: userName, password: password)
        )

        let service = urlService
        do {
            let response = try await NetworkTask.fetch(service, resource: resource)
            accessToken = response.accessToken
            isLoggedIn = true
        } catch {
            errorMessage = friendlyMessage(for: error)
        }

        isLoading = false
    }

    // MARK: - Logout

    func logout() {
        accessToken = nil
        isLoggedIn = false
        currentUser = nil
        errorMessage = nil
    }

    // MARK: - Helpers

    private func friendlyMessage(for error: Error) -> String {
        if let serviceError = error as? URLServiceError {
            switch serviceError {
            case .badStatusCode(let code, let data):
                let serverDetail = parseServerDetail(from: data)
                switch code {
                case 401: return serverDetail ?? "Неверный логин или пароль"
                case 409: return serverDetail ?? "Пользователь с таким именем уже существует"
                case 422: return serverDetail ?? "Проверьте введённые данные"
                case 500: return "Внутренняя ошибка сервера (500)\(serverDetail.map { ": \($0)" } ?? "")"
                case 502: return "Плохой шлюз (502)\(serverDetail.map { ": \($0)" } ?? "")"
                case 503: return "Сервис недоступен (503)\(serverDetail.map { ": \($0)" } ?? "")"
                case 504: return "Шлюз не отвечает (504)"
                default:  return serverDetail.map { "Ошибка \(code): \($0)" } ?? "Ошибка сервера (\(code))"
                }
            case .invalidURL:
                return "Ошибка конфигурации приложения"
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed:
                return "Нет интернет-соединения"
            case .timedOut:
                return "Превышено время ожидания"
            case .cannotConnectToHost, .cannotFindHost:
                return "Не удаётся подключиться к серверу"
            default:
                break
            }
        }

        return error.localizedDescription
    }

    /// Парсит поле `detail` из JSON-тела ответа FastAPI.
    private func parseServerDetail(from data: Data) -> String? {
        struct Envelope: Decodable {
            let detail: RawDetail

            enum RawDetail: Decodable {
                case text(String)
                case list([Item])
                struct Item: Decodable { let msg: String }

                init(from decoder: Decoder) throws {
                    let c = try decoder.singleValueContainer()
                    if let s = try? c.decode(String.self) { self = .text(s); return }
                    if let a = try? c.decode([Item].self) { self = .list(a); return }
                    throw DecodingError.typeMismatch(
                        RawDetail.self,
                        .init(codingPath: decoder.codingPath, debugDescription: "unexpected detail type")
                    )
                }

                var message: String {
                    switch self {
                    case .text(let s): return s
                    case .list(let items): return items.map(\.msg).joined(separator: "\n")
                    }
                }
            }
        }
        return (try? JSONDecoder().decode(Envelope.self, from: data))?.detail.message
    }
}
