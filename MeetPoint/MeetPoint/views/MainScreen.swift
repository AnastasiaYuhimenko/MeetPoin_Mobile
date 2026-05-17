//
//  MainScreen.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct MainScreen: View {
    var body: some View {
        TabView {
            Appointments()
                .tabItem {
                    Label("Мероприятия", systemImage: "calendar")
                }

            ContactsView()
                .tabItem {
                    Label("Контакты", systemImage: "person.2.fill")
                }

            RequestsView()
                .tabItem {
                    Label("Заявки", systemImage: "bell.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle")
                }
        }
        .tint(.appYellow)
        .toolbarBackground(Color.appBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainScreen()
}
