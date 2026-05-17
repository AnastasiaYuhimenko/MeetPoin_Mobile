//
//  MainView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct MainView: View {

    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        MainScreen()
            .errorToast($viewModel.errorMessage)
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel())
        .environmentObject(DeepLinkRouter())
}
