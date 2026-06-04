//
//  shimmer.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 03.06.2026.
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    var isActive: Bool = true
    @State private var start = UnitPoint(x: -1, y: -1)
    @State private var end = UnitPoint(x: 0, y: 0)

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.45), .white.opacity(0.2), .clear],
                        startPoint: start,
                        endPoint: end
                    )
                    .mask(content)
                }
            }
            .onAppear {
                guard isActive else { return }
                withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                    start = UnitPoint(x: 1, y: 1)
                    end = UnitPoint(x: 2, y: 2)
                }
            }
    }
}

extension View {
    func shimmering(active: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: active))
    }
}
