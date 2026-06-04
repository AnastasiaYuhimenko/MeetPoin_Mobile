//
//  UserProfileSkeleton.swift
//  MeetPoint
//

import SwiftUI

private let lightGray: Color = .gray.opacity(0.2)

struct UserProfileSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(lightGray)
                        .frame(width: 64, height: 64)
                        .shimmering()
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(lightGray)
                            .frame(width: 180, height: 22)
                            .shimmering()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(lightGray)
                            .frame(width: 120, height: 16)
                            .shimmering()
                    }
                    Spacer()
                }

                FlowLayout(spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule()
                            .fill(lightGray)
                            .frame(width: 72, height: 28)
                            .shimmering()
                    }
                }

                RoundedRectangle(cornerRadius: 8)
                    .fill(lightGray)
                    .frame(width: 100, height: 20)
                    .shimmering()

                RoundedRectangle(cornerRadius: 16)
                    .fill(lightGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 88)
                    .shimmering()

                RoundedRectangle(cornerRadius: 8)
                    .fill(lightGray)
                    .frame(width: 90, height: 20)
                    .shimmering()

                RoundedRectangle(cornerRadius: 16)
                    .fill(lightGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .shimmering()

                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 20)
                        .fill(lightGray)
                        .frame(width: 200, height: 44)
                        .shimmering()
                    Spacer()
                }
            }
            .padding()
        }
        .scrollDisabled(true)
    }
}
