//
//  AppointmentScreen.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 03.06.2026.
//

import SwiftUI

struct AppointmentScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    AppointmentCardSkelet()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}

struct AppointmentCardSkelet: View {
    private let lightGray: Color = .gray.opacity(0.2)
    private let gray: Color = .gray.opacity(0.5)
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                //                Text(appointment.title)
                //                    .font(.system(size: 20, weight: .semibold))
                //                    .foregroundStyle(Color.appPurple)
                //                    .lineLimit(2)
                //                    .truncationMode(.tail)
                //                    .layoutPriority(1)
                //                    .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 0, alignment: .leading)
                RoundedRectangle(cornerRadius: 16)
                    .fill(gray)
                    .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 0, alignment: .leading)
                    .frame(height: 24)
                    .padding(4)
                    .shimmering()
                Spacer()
                Capsule()
                    .fill(gray)
                    .frame(width: 80, height: 23)
                    .shimmering()
            }
            .padding(16)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .frame(width: 150, height: 20)
                .padding(16)
                .shimmering()
            //
            HStack(spacing: 6) {
                //                Image(systemName: "calendar")
                //                    .font(.caption)
                //                    .foregroundStyle(Color.appLightPurple)
                //                Text(formattedDate)
                //                    .font(.subheadline)
                //                    .foregroundStyle(.secondary)
                //
                //                Spacer()
                //
                //                Image(systemName: "person.2.fill")
                //                    .font(.caption)
                //                    .foregroundStyle(Color.appLightPurple)
                //                Text("\(appointment.participantsCount)")
                //                    .font(.subheadline)
                //                    .foregroundStyle(.secondary)
                //            }
                //            .padding(.vertical, 6)
                //
                //            Text(appointment.description)
                //                .font(.callout)
                //                .foregroundStyle(.secondary)
                //                .lineLimit(2)
                //                .frame(minHeight: 40)
                //
                            FlowLayout(spacing: 6) {
                                ForEach(0..<6, id: \.self) { tag in
                                    Capsule()
                                        .fill(gray)
                                        .frame(width: 65, height: 23)
                                        .shimmering()
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 95, alignment: .leading)
                            .padding(16)
            }
            .frame(maxWidth: .infinity, minHeight: 95, alignment: .leading)
            
            
            //
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(lightGray)
                .glassEffect(.identity, in:  RoundedRectangle(cornerRadius: 20))
                .shadow(
                    color: .appLightPurple.opacity(0.15),
                    radius: 10
                )
                .shimmering()
        )
    }
    
}

#Preview {
    AppointmentScreen()
}
