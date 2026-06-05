//
//  SkeletonLoaderContacts.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 05.06.2026.
//

import SwiftUI

struct ContactsSkeletonView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    ContactRowSkeleton()
                }
            }
            .navigationTitle("Контакты")
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

private struct ContactRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .shimmering()

                Text("Lo")
                    .foregroundStyle(Color.clear)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Lottie1234")
                    .font(.headline)
                    .foregroundStyle(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray)
                    )
                    .shimmering()

                Text("mobile")
                    .font(.caption)
                    .foregroundStyle(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray.opacity(0.7))
                    )
                    .shimmering()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Label("Не указан", systemImage: "envelope.fill")
                    .font(.caption2)
                    .foregroundStyle(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray)
                    )
                    .shimmering()
                    .padding(.vertical, 8)
                Divider()
                Label("Не указан", systemImage: "envelope.fill")
                    .font(.caption2)
                    .foregroundStyle(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray)
                    )
                    .shimmering()
                    .padding(.vertical, 8)
            }
            .containerRelativeFrame(.horizontal, count: 3, spacing: 0, alignment: .trailing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.3))
                .shimmering()
        )
    }
}

#Preview {
    ContactsSkeletonView()
}
