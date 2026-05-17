//
//  ProfileViewModel.swift
//  MeetPoint
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profileName = ""
    @Published var userName = ""
    @Published var position: MeetPoint.position = .other
    @Published var selectedTags: Set<Tag> = []
    @Published var email = ""
    @Published var telegram = ""
    @Published var about = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var successMessage: String?

    private var savedSnapshot: ProfileSnapshot?

    private let authService = URLService.auth

    var hasChanges: Bool {
        guard let saved = savedSnapshot else { return false }
        return profileName != saved.profileName
            || position != saved.position
            || selectedTags != saved.tags
            || email != saved.email
            || telegram != saved.telegram
            || about != saved.about
    }

    var canSave: Bool {
        hasChanges && isFormValid && !isSaving
    }

    var validationMessage: String? {
        if profileName.count > 100 {
            return "Имя не длиннее 100 символов"
        }
        if !email.isEmpty && !isEmailValid {
            return "Укажите email в формате name@mail.com"
        }
        if !telegram.isEmpty && !isTelegramValid {
            return "Укажите telegram: @username"
        }
        return nil
    }

    private var isFormValid: Bool {
        profileName.count <= 100 && (email.isEmpty || isEmailValid) && (telegram.isEmpty || isTelegramValid)
    }

    private var isEmailValid: Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }

    private var isTelegramValid: Bool {
        let handle = telegram.hasPrefix("@") ? String(telegram.dropFirst()) : telegram
        return !handle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var tagsToSave: [String] {
        if !selectedTags.isEmpty {
            return selectedTags.map(\.apiValue).sorted()
        }
        return savedSnapshot?.tags.map(\.apiValue).sorted() ?? []
    }

    private var hasLoaded = false

    func loadProfile(force: Bool = false) async {
        if hasLoaded && !force { return }
        if isLoading { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let resource = Resource<UserProfileDTO, GetMyProfileRequest>(
            request: GetMyProfileRequest(),
            decoder: .api
        )

        do {
            let profile = try await NetworkTask.fetch(authService, resource: resource)
            apply(profile)
            hasLoaded = true
        } catch {
            self.error = friendlyMessage(for: error)
        }
    }

    func save() async {
        guard canSave else { return }

        isSaving = true
        error = nil
        successMessage = nil
        defer { isSaving = false }

        let updateDto = UserUpdateDTO(
            name: profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : profileName.trimmingCharacters(in: .whitespacesAndNewlines),
            position: position.rawValue,
            tags: tagsToSave,
            about: about.isEmpty ? nil : about,
            telegram: normalizedTelegram,
            email: email.isEmpty ? nil : email
        )

        do {
            try await updateProfile(updateDto)
            successMessage = "Профиль сохранён"
        } catch {
            self.error = friendlyMessage(for: error)
        }
    }

    private func apply(_ profile: UserProfileDTO) {
        profileName = profile.name ?? ""
        userName = profile.userName
        position = MeetPoint.position(rawValue: profile.position) ?? .other
        selectedTags = Set(profile.tags.compactMap { Tag(apiValue: $0) })
        email = profile.email ?? ""
        telegram = profile.telegram ?? ""
        about = profile.about ?? ""
        storeSnapshot()
    }

    private func updateProfile(_ dto: UserUpdateDTO) async throws {
        let resource = Resource<UserResponseDTO, UpdateMyProfileRequest>(
            request: UpdateMyProfileRequest(dto: dto),
            decoder: .api
        )
        let updated = try await NetworkTask.fetch(authService, resource: resource)
        applyProfileResponse(updated)
    }

    private func applyProfileResponse(_ profile: UserResponseDTO) {
        profileName = profile.name ?? ""
        userName = profile.userName
        position = MeetPoint.position(rawValue: profile.position) ?? .other
        selectedTags = Set(profile.tags.compactMap { Tag(apiValue: $0) })
        email = profile.email ?? ""
        telegram = profile.telegram ?? ""
        about = profile.about ?? ""
        storeSnapshot()
    }

    private var normalizedTelegram: String? {
        guard !telegram.isEmpty else { return nil }
        return telegram.hasPrefix("@") ? telegram : "@\(telegram)"
    }

    private func storeSnapshot() {
        savedSnapshot = ProfileSnapshot(
            profileName: profileName,
            position: position,
            tags: selectedTags,
            email: email,
            telegram: telegram,
            about: about
        )
    }

    private func friendlyMessage(for error: Error) -> String {
        if let serviceError = error as? URLServiceError {
            switch serviceError {
            case .badStatusCode(let code, let data):
                let serverDetail = parseServerDetail(from: data)
                switch code {
                case 401: return serverDetail ?? "Сессия истекла, войдите снова"
                case 404: return serverDetail ?? "Обновление профиля недоступно на сервере"
                case 422: return serverDetail ?? "Проверьте введённые данные"
                default:
                    return serverDetail.map { "Ошибка \(code): \($0)" } ?? "Ошибка сервера (\(code))"
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

    private func parseServerDetail(from data: Data) -> String? {
        struct Envelope: Decodable {
            let detail: RawDetail

            enum RawDetail: Decodable {
                case text(String)
                case list([Item])
                struct Item: Decodable { let msg: String }

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    if let value = try? container.decode(String.self) {
                        self = .text(value)
                        return
                    }
                    if let items = try? container.decode([Item].self) {
                        self = .list(items)
                        return
                    }
                    throw DecodingError.typeMismatch(
                        RawDetail.self,
                        .init(codingPath: decoder.codingPath, debugDescription: "unexpected detail type")
                    )
                }

                var message: String {
                    switch self {
                    case .text(let value): return value
                    case .list(let items): return items.map(\.msg).joined(separator: "\n")
                    }
                }
            }
        }
        return (try? JSONDecoder().decode(Envelope.self, from: data))?.detail.message
    }
}

private struct ProfileSnapshot: Equatable {
    let profileName: String
    let position: MeetPoint.position
    let tags: Set<Tag>
    let email: String
    let telegram: String
    let about: String
}
