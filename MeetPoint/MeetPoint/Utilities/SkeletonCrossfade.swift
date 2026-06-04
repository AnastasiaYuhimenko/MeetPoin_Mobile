//
//  SkeletonCrossfade.swift
//  MeetPoint
//

import SwiftUI

struct SkeletonCrossfade<Content: View, Skeleton: View>: View {
    var showsSkeleton: Bool
    var fadeDuration: TimeInterval = 0.35
    var minimumSkeletonDuration: TimeInterval = 0.35
    @ViewBuilder var content: () -> Content
    @ViewBuilder var skeleton: () -> Skeleton

    @State private var skeletonOpacity: Double = 1
    @State private var skeletonShownAt: Date?

    var body: some View {
        ZStack(alignment: .top) {
            if skeletonOpacity < 1 {
                content()
                    .opacity(1 - skeletonOpacity)
                    .allowsHitTesting(skeletonOpacity < 0.5)
            }

            if skeletonOpacity > 0 {
                skeleton()
                    .opacity(skeletonOpacity)
                    .allowsHitTesting(skeletonOpacity >= 0.5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { syncSkeletonVisibility(animated: false) }
        .onChange(of: showsSkeleton) { _, _ in
            syncSkeletonVisibility(animated: true)
        }
    }

    private func syncSkeletonVisibility(animated: Bool) {
        if showsSkeleton {
            skeletonShownAt = Date()
            if animated {
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    skeletonOpacity = 1
                }
            } else {
                skeletonOpacity = 1
            }
            return
        }

        guard animated else {
            skeletonOpacity = 0
            return
        }

        Task { @MainActor in
            if let start = skeletonShownAt {
                let remaining = minimumSkeletonDuration - Date().timeIntervalSince(start)
                if remaining > 0 {
                    try? await Task.sleep(for: .seconds(remaining))
                }
            }
            withAnimation(.easeInOut(duration: fadeDuration)) {
                skeletonOpacity = 0
            }
        }
    }
}
