//
//  UserFacingNetworkMessage.swift
//  MeetPoint
//

import Foundation

/// Понятные сообщения пользователю на русском, без показа HTTP-кодов.
enum UserFacingNetworkMessage {

    enum Context: Sendable {
        case authentication
        case profile
        case appointmentsList
        case createEvent
        case editAppointment
        case joinAppointment
        case apiAction
    }

    static func parseServerDetail(from data: Data) -> String? {
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

    static func message(for error: Error, context: Context = .apiAction) -> String {
        if let decoding = error as? DecodingError {
            return decodingUserMessage(decoding)
        }

        if let serviceError = error as? URLServiceError {
            return message(for: serviceError, context: context)
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed:
                return "Нет подключения к интернету"
            case .timedOut:
                return "Превышено время ожидания"
            case .cannotConnectToHost, .cannotFindHost:
                return "Не удаётся подключиться к серверу"
            default:
                break
            }
        }

        let text = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "Не удалось выполнить действие" : text
    }

    // MARK: - Private

    private static func decodingUserMessage(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound, .typeMismatch, .valueNotFound, .dataCorrupted:
            return "Не удалось разобрать ответ сервера"
        @unknown default:
            return "Не удалось разобрать ответ сервера"
        }
    }

    private static func message(for error: URLServiceError, context: Context) -> String {
        switch error {
        case .invalidURL:
            return "Не удалось сформировать запрос к серверу"
        case .badStatusCode(let code, let data):
            let raw = parseServerDetail(from: data)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let detail = raw.flatMap { $0.isEmpty ? nil : $0 }
            return statusMessage(code: code, detail: detail, context: context)
        }
    }

    private static func pick(detail: String?, fallback: String) -> String {
        guard let detail, !detail.isEmpty else { return fallback }
        return detail
    }

    private static func statusMessage(code: Int, detail: String?, context: Context) -> String {
        switch code {
        case 400:
            switch context {
            case .createEvent:
                return pick(detail: detail, fallback: "Проверьте название мероприятия и теги")
            case .joinAppointment:
                return pick(detail: detail, fallback: "Не удалось присоединиться: выберите только теги этого мероприятия")
            default:
                return pick(detail: detail, fallback: "Не удалось выполнить запрос")
            }

        case 401:
            switch context {
            case .authentication:
                return pick(detail: detail, fallback: "Неверный логин или пароль")
            case .profile:
                return pick(detail: detail, fallback: "Сессия истекла — войдите снова")
            case .createEvent:
                return pick(detail: detail, fallback: "Войдите, чтобы создавать мероприятия")
            case .editAppointment:
                return pick(detail: detail, fallback: "Нет доступа к редактированию")
            case .joinAppointment:
                return pick(detail: detail, fallback: "Войдите, чтобы присоединиться к мероприятию")
            case .appointmentsList, .apiAction:
                return pick(detail: detail, fallback: "Сессия истекла — войдите снова")
            }

        case 403:
            switch context {
            case .editAppointment:
                return pick(detail: detail, fallback: "Только организатор может изменять мероприятие")
            case .joinAppointment:
                return pick(detail: detail, fallback: "Нет доступа к этому мероприятию")
            default:
                return pick(detail: detail, fallback: "Недостаточно прав для этого действия")
            }

        case 404:
            switch context {
            case .joinAppointment:
                return pick(detail: detail, fallback: "Мероприятие не найдено")
            case .profile:
                return pick(detail: detail, fallback: "Не удалось загрузить или сохранить профиль")
            case .appointmentsList:
                return pick(detail: detail, fallback: "Список мероприятий недоступен")
            default:
                return pick(detail: detail, fallback: "Запрошенные данные не найдены")
            }

        case 409:
            switch context {
            case .authentication:
                return pick(detail: detail, fallback: "Пользователь с таким именем уже существует")
            default:
                return pick(detail: detail, fallback: "Это действие уже нельзя выполнить")
            }

        case 422:
            switch context {
            case .joinAppointment:
                return pick(detail: detail, fallback: "Проверьте выбранные теги")
            default:
                return pick(detail: detail, fallback: "Проверьте введённые данные")
            }

        case 429:
            return pick(detail: detail, fallback: "Слишком много запросов — подождите немного")

        case 502, 503, 504:
            return pick(detail: detail, fallback: "Сервис временно недоступен")

        default:
            if (500 ..< 600).contains(code) {
                return "На сервере произошла ошибка. Попробуйте позже"
            }
            return pick(detail: detail, fallback: "Не удалось выполнить запрос")
        }
    }
}
