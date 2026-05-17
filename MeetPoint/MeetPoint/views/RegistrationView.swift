//
//  RegistrationView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import SwiftUI

struct RegistrationView: View {
    @Binding var userName: String
    @Binding var password: String
    @ObservedObject var viewModel: AuthViewModel
    var next: () -> Void
    var onLogin: (() -> Void)?

    @State private var usernameHadRejectedChars = false

    private var isUsernameEmpty: Bool { userName.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isUsernameTaken: Bool { viewModel.isUsernameAvailable == false }
    private var isUsernameChecking: Bool { !isUsernameEmpty && userName.count >= 3 && viewModel.isUsernameAvailable == nil }

    private var isPasswordLongEnough: Bool { password.count >= 8 }
    private var isPasswordHasLetter: Bool { password.contains(where: { $0.isLetter }) }
    private var isPasswordHasDigit: Bool { password.contains(where: { $0.isNumber }) }

    private var hasPasswordError: Bool { !isPasswordLongEnough || !isPasswordHasLetter || !isPasswordHasDigit }

    private var canProceed: Bool {
        viewModel.isUsernameAvailable == true && !hasPasswordError
    }

    private var englishUserName: Binding<String> {
        Binding(
            get: { userName },
            set: { newValue in
                let sanitized = EnglishUsernameInput.sanitized(newValue)
                usernameHadRejectedChars = (newValue != sanitized)
                userName = sanitized
            }
        )
    }

    private var latinUsernameHintNeutral: Bool { isUsernameEmpty && !usernameHadRejectedChars }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    Text("Регистрация")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    Spacer()
                    Image("meet")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    Spacer()
                    VStack(alignment: .leading, spacing: 0) {
                        CustomTextField(text: englishUserName, placeholderText: "Введите username")
                            .padding(.horizontal)
                            .padding(.top)

                        HStack(spacing: 6) {
                            if isUsernameChecking {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                            ValidationHint(
                                text: isUsernameChecking ? "Проверяем..." : "Username свободен",
                                isValid: viewModel.isUsernameAvailable == true,
                                isEmpty: isUsernameEmpty
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        ValidationHint(
                            text: "Только латиница, цифры и _",
                            isValid: !usernameHadRejectedChars,
                            isEmpty: latinUsernameHintNeutral
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)

                        CustomTextField(text: $password, placeholderText: "Придумайте пароль")
                            .padding(.horizontal)
                            .padding(.top, 16)

                        FlowLayout(spacing: 6) {
                            ValidationHint(text: "Минимум 8 символов", isValid: isPasswordLongEnough, isEmpty: password.isEmpty)
                            ValidationHint(text: "Содержит букву", isValid: isPasswordHasLetter, isEmpty: password.isEmpty)
                            ValidationHint(text: "Содержит цифру", isValid: isPasswordHasDigit, isEmpty: password.isEmpty)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    Spacer()

                    customButton(text: "Продолжить", action: next)
                        .opacity(canProceed ? 1 : 0.4)
                        .disabled(!canProceed)

                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onLogin?()
                    } label: {
                        Text("Уже есть аккаунт?")
                            .padding(.top, 8)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .task(id: userName) {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await viewModel.checkUsername(userName)
        }
    }
}
