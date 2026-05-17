//
//  AboutUser.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct AboutUser: View {
    
    @Binding var aboutUser: String
    var next: () -> Void
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Расскажите о себе")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("(Не обязательно)")
                        .foregroundStyle(.appLightPurple)

                    Spacer()

                    ZStack(alignment: .topLeading) {
                        if aboutUser.isEmpty {
                            Text("Я супер крутой разработчик из Беларуси. Мне 10 лет. Опыт в разработке 15 лет")
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 16)
                        }

                        TextEditor(text: $aboutUser)
                            .padding(8)
                            .frame(height: 400)
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.appPurple, lineWidth: 1)
                            )
                    }

                    Spacer()

                    customButton(text: "Начать знакомиться", action: next)
                        .padding(.bottom, 60)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                .padding()
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
