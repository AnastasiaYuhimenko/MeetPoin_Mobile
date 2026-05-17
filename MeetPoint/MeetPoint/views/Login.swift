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

    var onRegister: (() -> Void)?

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        !viewModel.isLoading
    }

    var body: some View {
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
            
            CustomTextField(text: $username, placeholderText: "Username")
                .padding(.vertical)

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
        .padding()
    }
}

#Preview {
    Login()
        .environmentObject(AuthViewModel())
}
