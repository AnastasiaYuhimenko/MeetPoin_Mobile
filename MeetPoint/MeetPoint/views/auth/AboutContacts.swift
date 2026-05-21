//
//  AboutContacts.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct AboutContacts: View {
    @Binding var profileName: String
    @Binding var userEmail: String
    @Binding var userTelegramm: String
    var next: () -> Void

    private var isNameValid: Bool { profileName.count <= 100 }

    private var isEmailValid: Bool {
        let parts = userEmail.split(separator: "@")
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }

    private var isTelegramValid: Bool {
        userTelegramm.hasPrefix("@") && userTelegramm.count > 1
    }

    private var canProceed: Bool {
        (userEmail.isEmpty || isEmailValid)
            && (userTelegramm.isEmpty || isTelegramValid)
            && (!userEmail.isEmpty || !userTelegramm.isEmpty)
            && isNameValid
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    Text("Добавьте хотябы один ")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 30)
                    Text("контакт")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 30)

                    Image("phoneCall")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                    VStack {
                        CustomTextField(text: $profileName, placeholderText: "Как вас зовут (необязательно)")

                        FlowLayout(spacing: 6) {
                            ValidationHint(
                                text: "Не больше 100 символов",
                                isValid: isNameValid,
                                isEmpty: profileName.isEmpty
                            )
                        }
                        .padding(.top, 6)

                        CustomTextField(text: $userEmail, placeholderText: "Email")
                            .padding(.top, 8)

                        FlowLayout(spacing: 6) {
                            ValidationHint(text: "Формат: name@mail.com", isValid: isEmailValid, isEmpty: userEmail.isEmpty)
                        }
                        .padding(.top, 6)

                        CustomTextField(text: $userTelegramm, placeholderText: "Telegram")
                            .padding(.top, 8)

                        FlowLayout(spacing: 6) {
                            ValidationHint(text: "Начинается с @", isValid: isTelegramValid, isEmpty: userTelegramm.isEmpty)
                        }
                        .padding(.top, 6)

                        Spacer()
                        customButton(text: "Продолжить", action: next)
                            .opacity(canProceed ? 1 : 0.4)
                            .disabled(!canProceed)
                            .padding(.bottom, 40)
                    }
                    .offset(y: -20)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                .padding()
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
