//
//  EditAppointmentView.swift
//  MeetPoint
//

import SwiftUI
import Networking

struct EditAppointmentView: View {
    let onUpdated: (Appointment) -> Void
    let onDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditAppointmentViewModel
    
    init(
        appointment: Appointment,
        onUpdated: @escaping (Appointment) -> Void,
        onDeleted: @escaping () -> Void = {}
    ) {
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
        _viewModel = StateObject(wrappedValue: EditAppointmentViewModel(appointment: appointment))
    }

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

                        if !viewModel.hasChanges {
                            Text("Измените данные, чтобы сохранить")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        saveButton
                            .padding(.top, 8)
                        deleteButton
                            
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(Color.appPurple)
                }
            }
            .errorToast($viewModel.errorMessage)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Измените мероприятие")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPurple)
            Text("Обновлённые данные увидят все участники.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var deleteButton: some View {
        Button {
            Task {
                if await viewModel.deleteAppointment() {
                    dismiss()
                    onDeleted()
                }
            }
        } label: {
            ZStack {
                HStack {
                    Text("Удалить мероприятие")
                }
                .fontWeight(.semibold)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lineWidth: 1)
                    .fill(Color.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
            }
        }
        .glassEffect(.regular.tint(Color.red.opacity(0.1)), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Название", systemImage: "textformat")
            CustomTextField(
                text: $viewModel.name,
                placeholderText: "Название мероприятия"
            )
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Дата и время", systemImage: "calendar")
            DatePicker(
                "",
                selection: $viewModel.date,
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
                    Text("Описание мероприятия")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var editTagSelectionHint: String {
        let count = viewModel.selectedTags.count
        if count == 0 {
            return "Выберите от \(TagSelectionLimits.minimum) до \(TagSelectionLimits.maximum) тегов"
        }
        if viewModel.isAtTagMaximum {
            return "Выбрано максимум \(TagSelectionLimits.maximum) тегов"
        }
        return "Выбрано \(count) из \(TagSelectionLimits.maximum)"
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Теги", systemImage: "tag")
            customTags(tags: $viewModel.selectedTags)
            Text(editTagSelectionHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                if let updated = await viewModel.save() {
                    onUpdated(updated)
                    dismiss()
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.appPurple)
                } else {
                    Text("Сохранить")
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(Color.appPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appYellow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.5)
    }

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
