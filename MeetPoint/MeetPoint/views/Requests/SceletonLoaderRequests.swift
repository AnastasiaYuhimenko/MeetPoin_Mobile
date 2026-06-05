//
//  SceletonLoaderRequests.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 05.06.2026.
//

import SwiftUI

struct RequestsSkeletonView: View {
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                RequestRowSkeleton()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

private struct RequestRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Color.gray)
                        .shimmering()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lottie1234")
                            .font(.headline)
                            .foregroundStyle(Color.clear)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.gray)
                            )
                            .shimmering()
                        
                        Text("mobile")
                            .font(.caption)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: true)
                            .foregroundStyle(.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        Color.gray
                                    )
                            )
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.clear)
                }

            FlowLayout(spacing: 6) {
                ForEach(0..<3) { tag in
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: 50, height: 20)
                        .shimmering()
                    
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                    Text("Отклонить")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(.clear)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(Color.gray.opacity(0.5))
                                .shimmering()
                        )
                        .clipShape(Capsule())

                
                    Text("Принять")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(Color.clear)
                        .background(Color.gray.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shimmering()
            }
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
    RequestsSkeletonView()
}
