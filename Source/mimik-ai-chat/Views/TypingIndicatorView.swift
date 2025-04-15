//
//  TypingIndicatorView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-21.
//

import SwiftUI

struct TypingIndicatorView: View {
    
    @State private var dotCount = 3
    @State private var isAnimating = true
    
    let animationDuration: Double
    let dotColor: Color
    
    var body: some View {
        HStack(spacing: 5) {
            // Display the dots with animation
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(dotColor)
                    .opacity(self.dotCount > index ? 1 : 0) // Control the opacity of each dot based on dotCount
                    .scaleEffect(self.isAnimating ? 1.2 : 1) // Scale the dots for effect
                    .animation(
                        Animation.easeInOut(duration: self.animationDuration).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            self.startDotAnimation()
        }
    }
    
    private func startDotAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            if self.isAnimating {
                self.dotCount = (self.dotCount % 3) + 1
                self.startDotAnimation()
            }
        }
    }
    
    func startAnimation() {
        isAnimating = true
    }
    
    func stopAnimation() {
        isAnimating = false
    }
}
