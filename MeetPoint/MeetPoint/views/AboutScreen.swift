//
//  AboutScreen.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import SwiftUI
import Combine

fileprivate enum RegistrationStage: Int {
    case registration = 0
    case contacts     = 1
    case work         = 2
    case about        = 3
}

struct AboutScreen: View {

    @EnvironmentObject var viewModel: AuthViewModel

    @State private var positionValue: position = .other
    @State private var tags: Set<Tag> = []
    @State private var profileName: String = ""
    @State private var userEmail: String = ""
    @State private var userTelegramm: String = ""
    @State private var aboutUser: String = ""
    @State private var userName: String = ""
    @State private var password: String = ""
    @State private var stage: RegistrationStage = .registration
    @State private var goingForward = true

    var onLogin: (() -> Void)?

    private func advance(to next: RegistrationStage) {
        goingForward = next.rawValue > stage.rawValue
        withAnimation(.easeInOut(duration: 0.35)) {
            stage = next
        }
    }

    private var slideInsertion: AnyTransition {
        goingForward
            ? .move(edge: .trailing).combined(with: .opacity)
            : .move(edge: .leading).combined(with: .opacity)
    }

    private var slideRemoval: AnyTransition {
        goingForward
            ? .move(edge: .leading).combined(with: .opacity)
            : .move(edge: .trailing).combined(with: .opacity)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch stage {
                case .registration:
                    RegistrationView(
                        userName: $userName,
                        password: $password,
                        viewModel: viewModel,
                        next: { advance(to: .contacts) },
                        onLogin: onLogin
                    )
                    .transition(.asymmetric(insertion: slideInsertion, removal: slideRemoval))
                case .contacts:
                    AboutContacts(
                        profileName: $profileName,
                        userEmail: $userEmail,
                        userTelegramm: $userTelegramm,
                        next: { advance(to: .work) }
                    )
                        .transition(.asymmetric(insertion: slideInsertion, removal: slideRemoval))
                case .work:
                    AboutWorkAndTags(positionValue: $positionValue, tags: $tags, next: { advance(to: .about) })
                        .transition(.asymmetric(insertion: slideInsertion, removal: slideRemoval))
                case .about:
                    AboutUser(aboutUser: $aboutUser, next: finishRegistration)
                        .transition(.asymmetric(insertion: slideInsertion, removal: slideRemoval))
                }

                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .appScreenBackground()
        }
    }

    private func finishRegistration() {
        QoSRunner.fireAndForgetUserInitiated {
            await viewModel.register(
                user: User(
                    id: nil,
                    name: profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? nil
                        : profileName.trimmingCharacters(in: .whitespacesAndNewlines),
                    userName: userName,
                    position: positionValue,
                    password: password,
                    tags: Array(tags),
                    telegram: userTelegramm.isEmpty ? nil : userTelegramm,
                    email: userEmail.isEmpty ? nil : userEmail,
                    about: aboutUser.isEmpty ? nil : aboutUser
                )
            )
        }
    }
}

#Preview {
    AboutScreen()
        .environmentObject(AuthViewModel())
}
