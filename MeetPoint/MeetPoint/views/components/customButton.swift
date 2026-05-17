//
//  customButton.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import SwiftUI

struct customButton: View {
    
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            action()
        } label: {
            Text(text)
                .foregroundStyle(Color.appPurple)
                .frame(width: 200, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color.appYellow)
                )
        }
    }
}

