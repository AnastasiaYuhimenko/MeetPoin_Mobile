//
//  MeetPointApp.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import SwiftUI

@main
struct MeetPointApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var deepLinkRouter = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authViewModel.isLoggedIn {
                    MainView()
                        .transition(.opacity)
                } else {
                    AuthFlowView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: authViewModel.isLoggedIn)
            .appScreenBackground()
            .preferredColorScheme(.light)
            .environmentObject(authViewModel)
            .environmentObject(deepLinkRouter)
            .onOpenURL { url in
                deepLinkRouter.handle(url: url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL {
                    deepLinkRouter.handle(url: url)
                }
            }
        }
    }
}
