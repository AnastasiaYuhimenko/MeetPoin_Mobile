//
//  CreateEventView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct CreateEventView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateEventViewModel()

    @State private var navigateToQR = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        nameField
                        dateField
                        descriptionField
                        tagsSection

                        Spacer(minLength: 8)

                        submitButton
                            .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Новое мероприятие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(Color.appPurple)
                }
            }
            .errorToast($viewModel.errorMessage)
            .navigationDestination(isPresented: $navigateToQR) {
                if let event = viewModel.createdEvent {
                    EventQRView(event: event) {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.createdEvent) { _, newValue in
                if newValue != nil {
                    navigateToQR = true
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Создайте мероприятие")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPurple)
            Text("Заполните данные — после создания вы получите QR-код со ссылкой для участников.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Название", systemImage: "textformat")
            CustomTextField(
                text: $viewModel.name,
                placeholderText: "Например, Хакатон Промразработки"
            )
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Дата и время", systemImage: "calendar")
            DatePicker(
                "",
                selection: $viewModel.date,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .environment(\.locale, Locale(identifier: "ru_RU"))
            .tint(Color.appPurple)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appPurple, lineWidth: 1)
            )
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Описание", systemImage: "text.alignleft")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appPurple, lineWidth: 1)
                    .frame(minHeight: 120)

                TextEditor(text: $viewModel.eventDescription)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                if viewModel.eventDescription.isEmpty {
                    Text("Расскажите о мероприятии, формате и для кого оно")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Теги", systemImage: "tag")
            customTags(tags: $viewModel.selectedTags)
            customTagInput
            customSelectedTags
            Text(tagSelectionHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var tagSelectionHint: String {
        let count = viewModel.selectedTags.count
        if count == 0 {
            return "Выберите от \(TagSelectionLimits.minimum) до \(TagSelectionLimits.maximum) тегов"
        }
        if viewModel.isAtTagMaximum {
            return "Выбрано максимум \(TagSelectionLimits.maximum) тегов"
        }
        return "Выбрано \(count) из \(TagSelectionLimits.maximum)"
    }

    private var customTagInput: some View {
        HStack(spacing: 10) {
            TextField("Добавить свой тег", text: $viewModel.customTagInput)
                .disabled(viewModel.isAtTagMaximum)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    viewModel.addCustomTag()
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.appPurple, lineWidth: 1)
                )

            Button {
                viewModel.addCustomTag()
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(Color.appPurple)
                    .frame(width: 44, height: 44)
                    .background(Color.appYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.canAddCustomTag)
            .opacity(viewModel.canAddCustomTag ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private var customSelectedTags: some View {
        if !viewModel.customSelectedTags.isEmpty {
            FlowLayout(spacing: 8) {
                ForEach(viewModel.customSelectedTags) { tag in
                    customTagPill(tag)
                }
            }
        }
    }

    private func customTagPill(_ tag: Tag) -> some View {
        HStack(spacing: 6) {
            Text(tag.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Button {
                viewModel.removeCustomTag(tag)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.appPurple)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.appLightPurple.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appLightPurple.opacity(0.5), lineWidth: 1))
    }

    private var submitButton: some View {
        HStack {
            Spacer()
            Button {
                QoSRunner.fireAndForgetUserInitiated {
                    await viewModel.createEvent()
                }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.appPurple)
                    }
                    Text(viewModel.isLoading ? "Создаём..." : "Создать мероприятие")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.appPurple)
                .frame(width: 260, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color.appYellow)
                )
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .opacity((viewModel.isFormValid && !viewModel.isLoading) ? 1 : 0.5)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(Color.appLightPurple)
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appPurple)
        }
    }
}

#Preview {
    CreateEventView()
}
