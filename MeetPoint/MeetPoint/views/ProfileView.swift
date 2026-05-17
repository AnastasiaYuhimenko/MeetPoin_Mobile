//
//  ProfileView.swift
//  MeetPoint
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var didRequestLoad = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.userName.isEmpty {
                    ProgressView("Загружаем профиль...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    profileForm
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                guard !didRequestLoad else { return }
                didRequestLoad = true
                QoSRunner.fireAndForgetUserInitiated {
                    await viewModel.loadProfile()
                }
            }
            .errorToast($viewModel.error)
            .alert("Готово", isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.successMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.successMessage = nil }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
        }
    }

    private var profileForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                displayNameSection
                usernameSection
                positionSection
                tagsSection
                contactsSection
                aboutSection
                if let hint = viewModel.validationMessage {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if !viewModel.hasChanges {
                    Text("Измените данные, чтобы сохранить")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                saveButton
                logoutButton
            }
            .padding(20)
        }
        .refreshable {
            await refreshProfile()
        }
    }

    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Имя", systemImage: "person.text.rectangle")
            CustomTextField(text: $viewModel.profileName, placeholderText: "Как вас зовут")
            Text("Показывается другим участникам; если пусто — виден только username")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Имя пользователя", systemImage: "person")
            Text(viewModel.userName)
                .font(.body)
                .foregroundStyle(Color.appPurple)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appMutedSurface)
                )
            Text("Имя пользователя нельзя изменить")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Должность", systemImage: "briefcase")
            Picker("", selection: $viewModel.position) {
                ForEach(MeetPoint.position.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
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

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Интересы", systemImage: "tag")
            customTags(tags: $viewModel.selectedTags)
        }
    }

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Контакты", systemImage: "phone")
            CustomTextField(text: $viewModel.email, placeholderText: "Email")
            CustomTextField(text: $viewModel.telegram, placeholderText: "Telegram")
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("О себе", systemImage: "text.alignleft")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appPurple, lineWidth: 1)
                    .frame(minHeight: 120)

                TextEditor(text: $viewModel.about)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                if viewModel.about.isEmpty {
                    Text("Расскажите о себе")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            QoSRunner.fireAndForgetUserInitiated {
                await viewModel.save()
            }
        } label: {
            Group {
                if viewModel.isSaving {
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

    private var logoutButton: some View {
        Button(role: .destructive) {
            authViewModel.logout()
        } label: {
            Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .padding(.top, 8)
    }

    private func refreshProfile() async {
        try? await QoSRunner.userInitiated {
            await viewModel.loadProfile(force: true)
        }
    }

    private func sectionLabel(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.appPurple)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
