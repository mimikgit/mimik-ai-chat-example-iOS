//
//  CustomBackgroundModifier.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-24.
//

import SwiftUI

struct CustomBackgroundModifier: ViewModifier {
    
    var backgroundColor: Color
    var cornerRadius: CGFloat?
    var borderColor: Color?
    var borderWidth: CGFloat = 1.0
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius ?? 0)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius ?? 0)
                    .stroke(borderColor ?? .clear, lineWidth: borderWidth)
            )
    }
}

extension View {
    func customBackground(backgroundColor: Color, cornerRadius: CGFloat? = nil, borderColor: Color? = nil, borderWidth: CGFloat = 1.0, padding: CGFloat = 16.0) -> some View {
        self.modifier(CustomBackgroundModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius, borderColor: borderColor, borderWidth: borderWidth, padding: padding))
    }
}
