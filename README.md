# MeetPoint — iOS-клиент

Мобильный клиент сервиса знакомств на мероприятиях. Участник сканирует QR-код
конференции, заполняет короткий профиль, видит ленту других участников
и отправляет запросы на знакомство. Контакты раскрываются только после
взаимного интереса.

> Кейс «MeetPoint» — Хакатон PROD: Минск 2026.

## Стек

- **iOS 17+**, Swift 5.10, SwiftUI + немного UIKit (карточка пользователя,
  QR-сканер на `AVCaptureSession`)
- Архитектура **MVVM** (`@MainActor` ViewModel + `ObservableObject`)
- Свой сетевой слой `URLService` поверх `URLSession` с retry и сохранением
  `Authorization` при HTTP-редиректах
- QR-генератор на `CIFilter.qrCodeGenerator`, deep links через URL scheme
  `meetpoint://event/<uuid>` и universal links `https://<host>/events/<uuid>`
- Бэкенд: FastAPI на `http://111.88.144.41:8000`,
  веб-фронт: `http://111.88.144.41:3000`

## Структура проекта

```
MeetPoint/
├── MeetPoint.xcodeproj/        — Xcode project + shared scheme
└── MeetPoint/
    ├── MeetPointApp.swift      — entry point, AuthFlow / MainView, deep links
    ├── Info.plist              — NSCameraUsageDescription, URL scheme
    ├── Models/                 — доменные модели (User, Tag, position)
    ├── ModelViews/             — все @MainActor ViewModel'ы
    │   ├── authViewModel.swift
    │   ├── AppointmentsViewModel.swift
    │   ├── AppointmentDetailViewModel.swift
    │   ├── ContactsViewModel.swift
    │   ├── RequestsViewModel.swift
    │   ├── CreateEventViewModel.swift
    │   └── DeepLinkRouter.swift
    ├── Networking/
    │   ├── URLService.swift    — Resource<T,R>, Requestable, retry-логика
    │   ├── AuthEndpoint.swift  — /register, /login, /check-username
    │   └── AppointmentEndpoint.swift — /appointments, /connections, /events
    └── views/
        ├── AuthFlowView.swift             — переключатель Login ↔ Register
        ├── AboutScreen.swift              — 4-шаговая регистрация
        ├── Login.swift
        ├── RegistrationView.swift
        ├── AboutContacts.swift
        ├── AboutWorkAndTags.swift
        ├── AboutUser.swift
        ├── MainView.swift / MainScreen.swift — TabView
        ├── Appointments.swift             — лента + детальный экран + статистика
        ├── CreateEventView.swift          — форма создания мероприятия
        ├── EventQRView.swift              — QR + share + admin token
        ├── QRScannerView.swift            — сканер QR на AVFoundation
        ├── ContactsView.swift             — мои контакты
        ├── RequestsView.swift             — входящие запросы
        ├── validationForField.swift       — FlowLayout, ValidationHint
        └── components/                    — переиспользуемые UI-блоки
```

## Запуск из Xcode (рекомендуемый способ)

1. Клонируй репозиторий.
2. Открой `MeetPoint/MeetPoint.xcodeproj` в Xcode 16+.
3. Выбери симулятор `iPhone 15` (или любое реальное устройство, добавленное
   в твою команду разработки).
4. ⌘R.

Бэкенд развернут на удалённой машине, конфигурация уже зашита
в `Networking/AppointmentEndpoint.swift` и `Networking/AuthEndpoint.swift`,
ничего больше настраивать не нужно.

## Сборка `.ipa` локально

```bash
./Scripts/build_ipa.sh             # Release без подписи
./Scripts/build_ipa.sh Debug       # Debug без подписи
CODESIGN=1 ./Scripts/build_ipa.sh  # Release с automatic signing (нужен Apple ID)
```

Результат: `build/ipa/MeetPoint-unsigned.ipa`.

### Установка `.ipa` на устройство

Unsigned `.ipa` нельзя поставить на устройство «как есть». Варианты:

- **Через Xcode (free Apple ID, 7 дней):** `Window → Devices and Simulators →
  + → drag-n-drop .ipa`. Подойдёт, если жюри готово открыть Xcode.
- **С подписью:** запустите `CODESIGN=1 ./Scripts/build_ipa.sh`, файл подпишется
  development-сертификатом активной команды.
- **На симуляторе:** распакуйте `.ipa` (`unzip MeetPoint-unsigned.ipa`)
  и установите `Payload/MeetPoint.app` через
  `xcrun simctl install booted Payload/MeetPoint.app`.

## CI/CD

`.gitlab-ci.yml` содержит четыре стадии:

| Стадия     | Job                  | Runner       | Что делает                                            |
| ---------- | -------------------- | ------------ | ----------------------------------------------------- |
| `validate` | `validate:structure` | linux/docker | Проверяет наличие обязательных файлов и shared scheme |
| `validate` | `validate:yaml`      | linux/docker | yamllint для `.gitlab-ci.yml`                         |
| `lint`     | `lint:swift`         | linux/docker | SwiftLint с junit-репортом                            |
| `build`    | `build:simulator`    | **macos**    | `xcodebuild` под iOS Simulator                        |
| `build`    | `build:ipa`          | **macos**    | `xcodebuild archive` + сборка unsigned `.ipa`         |
| `package`  | `package:release`    | linux/docker | Собирает исходники + `.ipa` в один артефакт релиза    |

`build:*` помечены `when: manual` и `tags: [macos]` — запускаются,
когда в группе появится macOS-раннер с Xcode.

## API

Все запросы идут через `URLService` с автоматическим retry
(`408/429/5xx`, timeouts, обрывы сети) и сохранением `Authorization`
при редиректах FastAPI с trailing slash.

| Метод | Путь                                          | Назначение                                |
| ----- | --------------------------------------------- | ----------------------------------------- |
| GET   | `/api/v1/check-username?username=...`         | Проверка занятости username при регистрации |
| POST  | `/api/v1/register`                            | Регистрация пользователя                  |
| POST  | `/api/v1/login`                               | Авторизация, возвращает `access_token`    |
| GET   | `/appointments`                               | Список мероприятий                        |
| POST  | `/appointments`                               | Создание мероприятия (для организатора)   |
| GET   | `/appointments/{id}`                          | Одно мероприятие                          |
| GET   | `/appointments/{id}/my-role`                  | Узнать, организатор я или участник        |
| GET   | `/appointments/{id}/participants`             | Лента участников                          |
| GET   | `/appointments/{id}/stats`                    | Статистика (только для организатора)      |
| POST  | `/connections/request`                        | Отправить запрос на знакомство            |
| GET   | `/connections/incoming`                       | Входящие запросы                          |
| POST  | `/connections/{id}/accept`                    | Принять запрос                            |
| POST  | `/connections/{id}/decline`                   | Отклонить запрос                          |
| GET   | `/connections/contacts`                       | Мои контакты (после взаимного интереса)   |

## Закрытые пункты кейса

| Сценарий                                                | Закрыт |
| ------------------------------------------------------- | ------ |
| Организатор создаёт мероприятие                         | ✅      |
| Получение QR-кода и публичной ссылки                    | ✅      |
| Дашборд статистики                                      | ✅      |
| Вход по QR / deep link на мероприятие                   | ✅      |
| Мини-профиль участника                                  | ✅      |
| Лента участников с тегами и кнопкой «Хочу познакомиться» | ✅      |
| Скрытие контактов до взаимного интереса                 | ✅      |
| Принятие / пропуск входящего запроса                    | ✅      |
| Раздел «Мои контакты»                                   | ✅      |
| Фильтр ленты по тегам                                   | планируется |
| Блок «Вам может быть интересно»                         | планируется |
