//
//  ScrollOffsetResetOnAppear.swift
//  MeetPoint
//

import SwiftUI
import UIKit

/// Сбрасывает родительский UIScrollView в начало (повторяет с задержкой после layout).
struct ScrollOffsetResetOnAppear: UIViewRepresentable {
    var trigger: Int = 0

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        scheduleResets(from: uiView)
    }

    private func scheduleResets(from view: UIView) {
        let delays: [TimeInterval] = [0, 0.05, 0.15, 0.35]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                resetScrollOffset(from: view)
            }
        }
    }

    private func resetScrollOffset(from view: UIView) {
        var ancestor: UIView? = view.superview
        var scrollViews: [UIScrollView] = []
        while let current = ancestor {
            if let scrollView = current as? UIScrollView {
                scrollViews.append(scrollView)
            }
            ancestor = current.superview
        }
        guard let scrollView = scrollViews.max(by: { $0.bounds.height < $1.bounds.height }) else { return }
        let topOffset = CGPoint(x: 0, y: -scrollView.adjustedContentInset.top)
        guard scrollView.contentOffset != topOffset else { return }
        scrollView.setContentOffset(topOffset, animated: false)
    }
}

extension View {
    func resetParentScrollOffset(trigger: Int = 0) -> some View {
        background(ScrollOffsetResetOnAppear(trigger: trigger))
    }
}
