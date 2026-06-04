//
//  ContactsView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI

struct ContactsView: View {
    @StateObject private var viewModel =  ContactsViewModel()
    @State private var selectedUser: User?
    @State private var didRequestLoad = false
    

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.contacts.isEmpty {
                    ProgressView("Загружаем контакты...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.contacts.isEmpty {
                    emptyState
                } else {
                    contactsList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Контакты")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                guard !didRequestLoad else { return }
                didRequestLoad = true
                QoSRunner.fireAndForgetUserInitiated {
                    await viewModel.loadContacts()
                }
            }
            .errorToast($viewModel.error)
            .sheet(item: $selectedUser) { user in
                VStack {
                    UserCellSheet(user: user, isFriend: true, hasOffer: false)
                        .padding(.top, 24)
                    Spacer()
                }
                .appScreenBackground()
                .presentationDetents([.medium])
                .presentationBackground(Color.appBackground)
            }
        }
    }

    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.contacts) { user in
                    Button {
                        selectedUser = user
                    } label: {
                        ContactRow(user: user)
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await refreshContacts()
        }
    }

    private var emptyState: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.appLightPurple)
                    Text("Пока нет контактов")
                        .font(.headline)
                        .foregroundStyle(Color.appPurple)
                    Text("Здесь появятся люди, с которыми\nсостоялось взаимное знакомство")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height,
                    alignment: .center
                )                .padding()
            }
            .refreshable {
                await refreshContacts()
            }
        }
    }

    private func refreshContacts() async {
        try? await QoSRunner.userInitiated {
            await viewModel.loadContacts(force: true)
        }
    }
}

// MARK: - Contact Row

private struct ContactRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appLightPurple)
                    .frame(width: 40, height: 40)
                    
                Text("\(user.displayName.prefix(2))")
                    .foregroundStyle(Color.white)
                    .font(.title2)
            }
            

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.appPurple)
                Text(user.position.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                if let telegram = user.telegram {
                    let cleanUsername = telegram.replacingOccurrences(of: "@", with: "")
                    Button {
                        if let url = URL(string: "https://t.me/\(cleanUsername)") {
                            UIApplication.shared.open(url)
                        }
                        
                    } label: {
                        HStack {
                            Label(telegram, systemImage: "paperplane.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.appLightPurple)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Label("Не указан", systemImage: "paperplane.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.appLightPurple)
                        .padding(.bottom)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.vertical, 8)

                }
                if let email = user.email {
                    Divider()
                    Button {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label(email, systemImage: "envelope.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Divider()
                    Label("Не указан", systemImage: "envelope.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .containerRelativeFrame(.horizontal, count: 3, spacing: 0, alignment: .trailing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appYellow.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appLightPurple.opacity(0.35), lineWidth: 1)
                )
               
        )
    }
}

#Preview {
    ContactsView()
}
