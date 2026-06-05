//
//  UserProfileView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 04.06.2026.
//

import SwiftUI

struct UserProfileView: View {
    let user: User
    var connectionStatus: ConnectionStatusState?
    var isCurrentUser: Bool = false
    var onConnect: (() -> Void)?
    var requestsViewModel: RequestsViewModel?
    var onConnectionAccepted: ((UUID) -> Void)?
    var onConnectionDeclined: ((UUID) -> Void)?

    private let contactColor = Color(#colorLiteral(red: 0.4690566063, green: 0.2891243398, blue: 0.7201970816, alpha: 1))

    private var showsContacts: Bool {
        isCurrentUser || connectionStatus == .contacts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(.appLightPurple)
                            .frame(width: 64, height: 64)
                        Text("\(user.displayName.prefix(2))")
                            .font(.title2)
                            .foregroundStyle(Color.white)
                            .fontWeight(.semibold)
                    }
                    //                    .padding()
                    VStack(alignment: .leading) {
                        Text("\(user.displayName)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(user.position.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding()
                    Spacer()
                }
                //                .padding()
                FlowLayout(spacing: 6) {
                    ForEach(user.tags) { tag in
                        Text("\(tag.rawValue)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .overlay(
                                Capsule()
                                    .stroke(lineWidth: 1)
                                    .foregroundStyle(Color.appLightPurple)
                            )
                    }
                }
                
                Divider()
                    .padding()
                if let about = user.about {
                    VStack(alignment: .leading) {
                        Text("О себе")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(about)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.appLightPurple.opacity(0.1))
                            )
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding()
                }

                if showsContacts {
                Text("Контакты")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                VStack {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(contactColor)
                            .font(.body)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16)
                                .fill(.appLightPurple.opacity(0.2)))
                            .padding()
                        if let telega = user.telegram {
                            let cleanUsername = telega.replacingOccurrences(of: "@", with: "")
                            
                            Button {
                                if let url = URL(string: "https://t.me/\(cleanUsername)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("Telegram")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appPurple)
                                    Text("\(telega)")
                                        .font(.subheadline)
                                        .foregroundStyle(contactColor)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .padding(.horizontal)
                                    .foregroundStyle(Color.appPurple)
                            }
                            
                        } else {
                            VStack(alignment: .leading) {
                                Text("Telegram")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appPurple)
                                Text("Не указан")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                            }
                            Spacer()
                        }
                    }
                    Divider()

                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(contactColor)
                            .font(.body)
                            .padding()
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 16)
                                .fill(.appLightPurple.opacity(0.2)))
                            .padding()
                        if let email = user.email {
                            Button {
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Email")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.appPurple)
                                        Text("\(email)")
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .foregroundStyle(contactColor)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .padding(.horizontal)
                                        .foregroundStyle(Color.appPurple)
                                }
                            }
                        } else {
                            VStack(alignment: .leading) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appPurple)
                                Text("Не указан")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                            }
                            Spacer()
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(Color.gray.opacity(0.5))
                )
                .padding(.horizontal)
                } else if !isCurrentUser {
                    Text("Контакты станут доступны после взаимного знакомства")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                if !isCurrentUser {
                    connectionActions
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

            }
            .padding()
            
        }
    }

    @ViewBuilder
    private var connectionActions: some View {
        HStack {
            Spacer()
            switch connectionStatus {
            case .some(.contacts):
                connectionPill(
                    title: "Уже в друзьях",
                    background: Color.appMutedSurface,
                    foreground: .secondary,
                    enabled: false
                )
            case .some(.outgoing):
                connectionPill(
                    title: "Заявка отправлена",
                    background: Color.appLightPurple.opacity(0.35),
                    foreground: Color.appPurple,
                    enabled: false
                )
            case .some(.incoming), .some(.declined):
                HStack(spacing: 12) {
                    Button {
                        Task {
                            guard let userId = user.id else { return }
                            await requestsViewModel?.declineByUserID(userId)
                            onConnectionDeclined?(userId)
                        }
                    } label: {
                        Text("Отклонить")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.appPurple)
                            .frame(width: 150, height: 45)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(lineWidth: 1)
                                    .foregroundStyle(Color.appPurple)
                            )
                    }
                    Button {
                        Task {
                            guard let userId = user.id else { return }
                            await requestsViewModel?.acceptByUserID(userId)
                            onConnectionAccepted?(userId)
                        }
                    } label: {
                        Text("Принять заявку")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.appPurple)
                            .frame(width: 150, height: 45)
                            .background(Color.appYellow)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            case .some(.unknown):
                connectionPill(
                    title: "Статус связи неизвестен",
                    background: Color.appMutedSurface,
                    foreground: .secondary,
                    enabled: false
                )
            default:
                HStack {
                    Spacer()
                    Button {
                        onConnect?()
                    } label: {
                        Text("Добавить в друзья")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.appPurple)
                            .frame(width: 200, height: 50)
                            .background(Color.appYellow)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private func connectionPill(
        title: String,
        background: Color,
        foreground: Color,
        enabled: Bool
    ) -> some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundStyle(foreground)
            .frame(width: 200, height: 44)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .allowsHitTesting(enabled)
    }
}


struct UserProfileDestination: View {
    @StateObject private var profileViewModel: UserProfileViewModel

    var connectionStatus: ConnectionStatusState?
    var isCurrentUser: Bool = false
    var onConnect: (() -> Void)?
    var requestsViewModel: RequestsViewModel?
    var onConnectionAccepted: ((UUID) -> Void)?
    var onConnectionDeclined: ((UUID) -> Void)?
    var onLoadConnectionStatus: (() async -> Void)?

    init(
        user: User,
        connectionStatus: ConnectionStatusState? = nil,
        isCurrentUser: Bool = false,
        onConnect: (() -> Void)? = nil,
        requestsViewModel: RequestsViewModel? = nil,
        onConnectionAccepted: ((UUID) -> Void)? = nil,
        onConnectionDeclined: ((UUID) -> Void)? = nil,
        onLoadConnectionStatus: (() async -> Void)? = nil
    ) {
        _profileViewModel = StateObject(
            wrappedValue: UserProfileViewModel(initialUser: user, isCurrentUser: isCurrentUser)
        )
        self.connectionStatus = connectionStatus
        self.isCurrentUser = isCurrentUser
        self.onConnect = onConnect
        self.requestsViewModel = requestsViewModel
        self.onConnectionAccepted = onConnectionAccepted
        self.onConnectionDeclined = onConnectionDeclined
        self.onLoadConnectionStatus = onLoadConnectionStatus
    }

    var body: some View {
        SkeletonCrossfade(
            showsSkeleton: profileViewModel.showsSkeleton,
            minimumSkeletonDuration: 0.35
        ) {
            UserProfileView(
                user: profileViewModel.user,
                connectionStatus: connectionStatus,
                isCurrentUser: isCurrentUser,
                onConnect: onConnect,
                requestsViewModel: requestsViewModel,
                onConnectionAccepted: onConnectionAccepted,
                onConnectionDeclined: onConnectionDeclined
            )
        } skeleton: {
            UserProfileSkeleton()
        }
        .appScreenBackground()
        .errorToast($profileViewModel.error)
        .onAppear {
            Task {
                async let profile: Void = profileViewModel.loadProfile(force: true)
                async let connection: Void = onLoadConnectionStatus?() ?? ()
                _ = await (profile, connection)
            }
        }
    }
}

#Preview("Добавить в друзья") {
    UserProfileView(
        user: User(id: UUID(), name: "Lottie", userName: "Lottie", position: .mobile, password: "SequrePassword123", tags: [.backend, .mobile], telegram: "@telega", email: "verylongpost@gmail.com", about: "Mobile-разработчик с маленьким опытом.", isEventOrganizer: false),
        connectionStatus: .none
    )
}

#Preview("Заявка отправлена") {
    UserProfileView(
        user: userDevelop.user,
        connectionStatus: .outgoing(requestId: nil)
    )
}

//
//if let telegram = user.telegram {
//    let cleanUsername = telegram.replacingOccurrences(of: "@", with: "")
//    Button {
//        if let url = URL(string: "https://t.me/\(cleanUsername)") {
//            UIApplication.shared.open(url)
//        }
//        
//    } label: {
//        HStack {
//            Label(telegram, systemImage: "paperplane.fill")
//                .font(.caption2)
//                .foregroundStyle(Color.appLightPurple)
//                .lineLimit(1)
//                .truncationMode(.tail)
//            Spacer()
//            Image(systemName: "chevron.right")
//        }
//    }
//    .padding(.vertical, 8)
//} else {
//    Label("Не указан", systemImage: "paperplane.fill")
//        .font(.caption2)
//        .foregroundStyle(Color.appLightPurple)
//        .padding(.bottom)
//        .lineLimit(1)
//        .truncationMode(.tail)
//        .padding(.vertical, 8)
//
//}
//if let email = user.email {
//    Divider()
//    Button {
//        if let url = URL(string: "mailto:\(email)") {
//            UIApplication.shared.open(url)
//        }
//    } label: {
//        HStack {
//            Label(email, systemImage: "envelope.fill")
//                .font(.caption2)
//                .foregroundStyle(.secondary)
//                .lineLimit(1)
//                .truncationMode(.tail)
//            Spacer()
//            Image(systemName: "chevron.right")
//        }
//    }
//    .padding(.vertical, 8)
//} else {
//    Divider()
//    Label("Не указан", systemImage: "envelope.fill")
//        .font(.caption2)
//        .foregroundStyle(.secondary)
//        .padding(.vertical, 8)
//}
