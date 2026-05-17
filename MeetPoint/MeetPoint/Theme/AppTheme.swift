//
//  AppTheme.swift
//  MeetPoint
//

import SwiftUI
import UIKit

extension Locale {
    static let russian = Locale(identifier: "ru_RU")
}

extension Color {
    /// Основной фон экранов — всегда белый, не зависит от системной темы.
    static let appBackground = Color.white
    /// Фон карточек и блоков.
    static let appCard = Color.white
    /// Ненавязчивый фон для чипов, переключателей и неактивных элементов.
    static let appMutedSurface = Color(red: 0.94, green: 0.94, blue: 0.96)
}

extension UIColor {
    static let appBackground = UIColor.white
    static let appCard = UIColor.white
    static let appMutedSurface = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
//    static let appPurple = UIColor(red: 0.36, green: 0.20, blue: 0.55, alpha: 1)
}

enum AppNavigationBarAppearance {
    static func applyLight() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.appPurple
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.appPurple
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .appPurple
    }
}

struct AppScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appBackground.ignoresSafeArea())
    }
}

struct AppNavigationChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // Keep large titles stable when returning to tabs by explicitly styling the scroll edge too.
//            .toolbarBackground(Color.appBackground, for: .navigationBar, .scrollEdge)
//            .toolbarBackground(.visible, for: .navigationBar, .scrollEdge)
            .toolbarColorScheme(.light, for: .navigationBar)
//            .toolbarColorScheme(.light, for: .navigationBar, .scrollEdge)
            .onAppear {
                AppNavigationBarAppearance.applyLight()
            }
    }
}

extension View {
    func appScreenBackground() -> some View {
        modifier(AppScreenBackgroundModifier())
    }

    func appNavigationChrome() -> some View {
        modifier(AppNavigationChromeModifier())
    }
}
