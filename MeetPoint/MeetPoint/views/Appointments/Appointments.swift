//
//  Appointments.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI
import UIKit
// MARK: - Model

struct Appointment: Identifiable, Hashable {
    let id: UUID
    let title: String
    let date: Date
    let description: String
    let tags: [Tag]
    let allTags: [String]
    let participantsCount: Int
    let isParticipating: Bool
    let isAdmin: Bool

    init(
        id: UUID,
        title: String,
        date: Date,
        description: String,
        tags: [Tag],
        participantsCount: Int,
        isParticipating: Bool = false,
        isAdmin: Bool = false,
        allTags: [String]
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.description = description
        self.tags = tags
        self.participantsCount = participantsCount
        self.isParticipating = isParticipating
        self.isAdmin = isAdmin
        self.allTags = allTags
    }
}

struct Appointments: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @StateObject var viewModel = AppointmentsViewModel()
    @State var selectedAppointment: Appointment?
    @State private var showCreateEvent = false
    @State private var showScanner = false
    @State private var isResolvingDeepLink = false
    @State var page: Int = 0
    @State var profileViewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            SkeletonCrossfade(
                showsSkeleton: viewModel.shouldShowSkeleton
            ) {
                Group {
                    if viewModel.error != nil, viewModel.appointments.isEmpty {
                        errorState
                    } else if viewModel.appointments.isEmpty,
                              !viewModel.isLoading,
                              !viewModel.hasActiveFilters {
                        appointmentEmptyState
                    } else {
                        appointmentsList
                    }
                }
            } skeleton: {
                AppointmentScreen()
            }
            .background(Color.appBackground)
            .navigationTitle("Мероприятия")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isFiltrShowing.toggle()
                    } label: {
                        Image("filter")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                }

                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appPurple)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                }

                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appYellow)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                }
            }
            .navigationDestination(item: $selectedAppointment) { appointment in
                AppointmentDetailView(
                    appointment: appointment,
                    onAppointmentUpdated: { updated in
                        viewModel.replaceAppointment(updated)
                        selectedAppointment = updated
                    },
                    onAppointmentDeleted: {
                        viewModel.removeAppointment(id: appointment.id)
                        selectedAppointment = nil
                    },
                    curUserTags: profileViewModel.selectedTags.map(\.rawValue)
                )
                .id(appointment.id)
            }
            .sheet(isPresented: $showCreateEvent, onDismiss: {
                QoSRunner.fireAndForgetUserInitiated {
                    await viewModel.loadAppointments(force: true, page: viewModel.page)
                }
            }) {
                CreateEventView(
                    selectedTags: profileViewModel.selectedTags.map(\.rawValue)
                )
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    QRScannerView { url in
                        deepLinkRouter.handle(url: url)
                    }
                }
            }
            .sheet(isPresented: $isFiltrShowing) {
                appointmentsFilters
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.appBackground)
            }
            .overlay {
                if isResolvingDeepLink {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        ProgressView("Открываем мероприятие...")
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.appCard)
                            )
                    }
                }
            }
            .task {
                viewModel.page = page
                try? await QoSRunner.userInitiated {
                    await viewModel.loadAppointments(page: page)
                }
                if let id = deepLinkRouter.pendingAppointmentId {
                    try? await QoSRunner.userInitiated {
                        await openAppointment(id: id)
                    }
                }
            }
            .onChange(of: deepLinkRouter.pendingAppointmentId) { _, newValue in
                guard let id = newValue else { return }
                QoSRunner.fireAndForgetUserInitiated {
                    await openAppointment(id: id)
                }
            }
            .errorToast($viewModel.error)
        }
    }

    
    private func openAppointment(id: UUID) async {
        showScanner = false
        showCreateEvent = false

        isResolvingDeepLink = true
        defer { isResolvingDeepLink = false }

        if let appointment = await viewModel.fetchAppointment(id: id) {
            selectedAppointment = appointment
        }
        deepLinkRouter.clearAppointment()
    }
    @State var isFiltrShowing: Bool = false

    private var appointmentEmptyState: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    appointmentsPlaceholderContent(
                        systemImage: "calendar.badge.exclamationmark",
                        title: "Нет мероприятий"
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height,
                    alignment: .center
                )

            }
            .refreshable {
                await refreshAppointments()
            }
        }
    }

    private var errorState: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    appointmentsPlaceholderContent(
                        systemImage: "wifi.slash",
                        title: "Не удалось загрузить"
                    )

                    customButton(text: "Повторить") {
                        Task {
                            await viewModel.loadAppointments(
                                force: true,
                                page: viewModel.page
                            )
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height,
                    alignment: .center
                )
            }
            .refreshable {
                await refreshAppointments()
            }
        }
    }

    private func appointmentsPlaceholderContent(systemImage: String, title: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(Color.appLightPurple)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appPurple)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
//        .padding(.top, 48)
//        .padding(.bottom, 32)
    }

    func refreshAppointments() async {
        try? await QoSRunner.userInitiated {
            await viewModel.loadAppointments(force: true, page: viewModel.page)
        }
    }
}

#Preview {
    Appointments()
        .environmentObject(AuthViewModel())
        .environmentObject(DeepLinkRouter())
}
