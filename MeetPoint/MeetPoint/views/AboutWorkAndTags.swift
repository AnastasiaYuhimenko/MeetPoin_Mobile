//
//  AboutWorkAndTags.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct AboutWorkAndTags: View {

    @Binding var positionValue: position
    @Binding var tags: Set<Tag>
    var next: () -> Void

    private var hasTagSelected: Bool { !tags.isEmpty }
    private var canProceed: Bool { hasTagSelected }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Расскажите про ваши интересы")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            Text("Кем вы работаете?")
                .font(.title3)

            Picker("", selection: $positionValue) {
                ForEach(MeetPoint.position.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.appPurple)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.appYellow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.vertical)

            Text("Выберите интересующие направления")
                .font(.title3)

            customTags(tags: $tags)
                .padding(.vertical)

            FlowLayout(spacing: 6) {
                ValidationHint(
                    text: "Выберите хотя бы одно направление",
                    isValid: hasTagSelected,
                    isEmpty: tags.isEmpty
                )
            }

            Spacer()

            customButton(text: "Продолжить", action: next)
                .opacity(canProceed ? 1 : 0.4)
                .disabled(!canProceed)
                .padding(.bottom, 60)
        }
        .padding()
    }
}
