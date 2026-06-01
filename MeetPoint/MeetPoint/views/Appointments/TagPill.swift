//
//  TagPill.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 31.05.2026.
//

import SwiftUI

struct TagPill: View {
    let tag: String
    let userTags: [String]
    var body: some View {
        GlassEffectContainer {
            Text(tag)
                .font(.system(size: 13))
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(Color.appPurple)
                .overlay(Capsule().stroke(Color.appLightPurple.opacity(0.7), lineWidth: 1))
                .glassEffect(.regular.tint(userTags.contains(tag) ? .appLightPurple.opacity(0.3) :  .appYellow.opacity(0.3)))
        }
    }
}
