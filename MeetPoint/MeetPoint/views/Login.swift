//
//  Login.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct Login: View {

    @EnvironmentObject var viewModel: AuthViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var usernameHadRejectedChars = false

    var onRegister: (() -> Void)?

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        !viewModel.isLoading
    }

    private var isUsernameEmpty: Bool { username.trimmingCharacters(in: .whitespaces).isEmpty }

    private var englishUsername: Binding<String> {
        Binding(
            get: { username },
            set: { newValue in
                let sanitized = EnglishUsernameInput.sanitized(newValue)
                usernameHadRejectedChars = (newValue != sanitized)
                username = sanitized
            }
        )
    }

    private var latinUsernameHintNeutral: Bool { isUsernameEmpty && !usernameHadRejectedChars }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    Text("С возвращением!")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Image("meet")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    Spacer()

                    CustomTextField(text: englishUsername, placeholderText: "Username")
                        .padding(.vertical)

                    ValidationHint(
                        text: "Только латиница, цифры и _",
                        isValid: !usernameHadRejectedChars,
                        isEmpty: latinUsernameHintNeutral
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    CustomTextField(text: $password, placeholderText: "Password")

                    VStack(spacing: 12) {
                        customButton(
                            text: viewModel.isLoading ? "Входим..." : "Войти",
                            action: {
                                QoSRunner.fireAndForgetUserInitiated {
                                    await viewModel.auth(userName: username, password: password)
                                }
                            }
                        )
                        .opacity(canSubmit ? 1 : 0.4)
                        .disabled(!canSubmit)
                        .padding(.top)

                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            onRegister?()
                        } label: {
                            Text("Ещё нет аккаунта?")
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    Login()
        .environmentObject(AuthViewModel())
}
