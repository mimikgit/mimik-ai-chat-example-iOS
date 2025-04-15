//
//  CustomTextField.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-07.
//

import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var foregroundColor: Color
    var backgroundColor: Color
    var fontSize: CGFloat
    var cornerRadius: CGFloat = 10
    var borderColor: Color = .clear
    var borderWidth: CGFloat = 0

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .font(.system(size: fontSize))
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .padding(.horizontal)
    }
}
