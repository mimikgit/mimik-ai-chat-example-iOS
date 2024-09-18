//
//  ContentView+UI-Labels.swift
//

import Foundation
import SwiftUI

internal extension ContentView {
    
    func downloadModelIcon() -> String {
        
        if activeStream != nil {
            return "hourglass"
        }
        else if downloadedModels.isEmpty {
            return "square.and.arrow.down"
        }
        else {
            return "gear"
        }
    }
    
    func downloadModelLabel() -> String {
        
        if activeStream != nil {
            return ""
        }
        else if downloadedModels.isEmpty {
            return "START HERE"
        }
        else {
            return "Manage Download\(downloadedModels.count > 1 ? "s" : "")"
        }
    }
    
    func userInputPrompt() -> String {
        
        if isWaiting {
            return "Please Wait..."
        }
        
        return downloadedModels.count >= 1 ? "Enter your question here" : ""
    }
    
    func userInputColour() -> Color {
        
        if isWaiting {
            return .gray
        }
        
        return downloadedModels.count >= 1 ? .red : .clear
    }
    
    func userInputStyle() -> any ShapeStyle {
        
        if isWaiting {
            return .gray
        }
        
        return downloadedModels.count >= 1 ? .red : .gray
    }
}
