//
//  AuthFlowView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct AuthFlowView: View {

    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showLogin = false

    var body: some View {
        ZStack {
            if showLogin {
                Login(onRegister: { showLogin = false })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                AboutScreen(onLogin: { showLogin = true })
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showLogin)
        .appScreenBackground()
        .errorToast($viewModel.errorMessage)
    }
}

#Preview {
    AuthFlowView()
        .environmentObject(AuthViewModel())
}
