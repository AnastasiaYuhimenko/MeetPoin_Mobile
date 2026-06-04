//
//  AppointmentDetailSceleton.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 03.06.2026.
//

import SwiftUI


fileprivate let lightGray: Color = .gray.opacity(0.2)
fileprivate let gray: Color = .gray.opacity(0.5)

struct AppointmentDetailSceleton: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            eventHeader
            eventQRCard
            TabSwitcherSceletonSceleton()
            Text("Участники")
                .font(.title)
                .foregroundStyle(.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(lightGray)
                )
        }
        .padding(20)
    }
        
    var eventHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label("4 июня 2026г.", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(lightGray)
                    )
                    .shimmering()
                Spacer()
                Label("2", systemImage: "person.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(lightGray)
                    )
                    .shimmering()
            }
            Text("28–30 марта в технопарке состоится трёхдневный хакатон для iOS- и Android-разработчиков, дизайнеров и product-менеджеров.")
                .foregroundStyle(.clear)
                .lineSpacing(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(lightGray)
                )
                .padding(.vertical)
                .shimmering()
            FlowLayout(spacing: 6) {
                ForEach(0..<10) { tag in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(lightGray)
                        .frame(width: 60, height: 25)
                        .shimmering()
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
        }
    }
    
    private var eventQRCard: some View {
        VStack(spacing: 14) {
            Text("QR-код для присоединения")
                .fontWeight(.semibold)
                .foregroundStyle(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gray)
                )
                .shimmering()
            
            Text("Отсканируйте камерой, чтобы присоединиться")
                .foregroundStyle(.clear)
                .multilineTextAlignment(.center)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(lightGray)
                )
                .shimmering()
            
            Text("Если приложение установлено — откроется оно. Иначе откроется сайт мероприятия.")
                .font(.caption)
                .foregroundStyle(.clear)
                .multilineTextAlignment(.center)
                .padding(.vertical)
                .shimmering()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(lightGray)
                .frame(width: 150, height: 150)
                .padding(.vertical)
                .shimmering()
           
            Text("https//localhost:8000/docs")
                .font(.caption2.monospaced())
                .foregroundStyle(.clear)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(lightGray)
                )
                .shimmering()
                .padding(.vertical)
            
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(lightGray)
                .shimmering()
        )
    }
}

private struct TabSwitcherSceletonSceleton: View {
    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 16)
                .fill(gray)
                .frame(height: 45)
                .shimmering()
            RoundedRectangle(cornerRadius: 16)
                .fill(lightGray)
                .frame(height: 45)
                .shimmering()
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16).fill(lightGray).shimmering())
    }
}



#Preview {
    AppointmentDetailSceleton()
}
