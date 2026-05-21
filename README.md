# MeetPoint — iOS-клиент

Мобильный клиент сервиса знакомств на мероприятиях. Участник сканирует QR-код
конференции, заполняет короткий профиль, видит ленту других участников
и отправляет запросы на знакомство. Контакты раскрываются только после
взаимного интереса.

> Кейс «MeetPoint» — Хакатон PROD: Минск 2026.
Результат - 4 место на хакатоне

## Стек

- **iOS 26+**, Swift 5.10, SwiftUI + немного UIKit (карточка пользователя,
  QR-сканер на `AVCaptureSession`)
- Архитектура **MVVM** 
- Свой сетевой слой `URLService` поверх `URLSession` с retry и сохранением
  `Authorization` при HTTP-редиректах
- QR-генератор на `CIFilter.qrCodeGenerator`, deep links через URL scheme
  `meetpoint://event/<uuid>` и universal links `https://<host>/events/<uuid>`
- Бэкенд: FastAPI на `http://111.88.144.41:8000`,
  веб-фронт: `http://111.88.144.41:3000` (сервер сейчас остановлен)

## Структура проекта

```
MeetPoint/
├── MeetPoint.xcodeproj/    
└── MeetPoint/
    ├── MeetPointApp.swift      — entry point, AuthFlow / MainView, deep links
    ├── Info.plist              — NSCameraUsageDescription, URL scheme
    ├── Models/                 — модели (User, Tag, position)
    ├── ModelViews/             — все ViewModels
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
        |-- Auth/
        |    ├── AuthFlowView.swift             — переключатель Login ↔ Register
        |    ├── AboutScreen.swift              — 4-шаговая регистрация
        |    ├── Login.swift
        |    ├── RegistrationView.swift
        |    ├── AboutContacts.swift
        |    ├── AboutWorkAndTags.swift
        |    └── AboutUser.swift
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
| Фильтр ленты по тегам                                   | ✅      |
| Блок «Вам может быть интересно»                         | планируется |
