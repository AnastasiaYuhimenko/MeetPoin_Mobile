//
//  CustomTextField.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 15.05.2026.
//

import SwiftUI

struct CustomTextField: View {
    
    @Binding var text: String
    let placeholderText: String
    var body: some View {
        ZStack {
           
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appPurple, lineWidth: 1)
                .frame(height: 40)
            TextField(text: $text) {
                Text(placeholderText)
            }
            .padding()
                
        }
    }
}
