//
//  AppointmentsList.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 01.06.2026.
//

import SwiftUI

extension Appointments {
    var appointmentsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if viewModel.appointments.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.appLightPurple)
                        Text("По выбранным фильтрам ничего не найдено")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if viewModel.hasActiveFilters {
                            customButton(text: "Сбросить фильтры") {
                                viewModel.resetAllFilters()
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.appointments) { appointment in
                            Button {
                                selectedAppointment = appointment
                            } label: {
                                AppointmentCard(appointment: appointment, selectedTags: profileViewModel.selectedTags.map({ $0.rawValue }))
                                    .contentShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await refreshAppointments()
        }
        .sheet(isPresented: $isFiltrShowing) {
            appointmentsFilters
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }
}
