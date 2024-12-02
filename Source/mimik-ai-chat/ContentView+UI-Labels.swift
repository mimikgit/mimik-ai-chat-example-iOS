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
            return "gear.badge"
        }
        else {
            return "gear"
        }
    }
    
    func downloadModelFont() -> Font {
        if selectedModel != nil && downloadedModels.count >= 1 {
            .title3
        }
        else {
            .title
        }
    }
    
    func downloadModelColour() -> Color {
        
        if downloadedModels.count >= 1 {
            if selectedModel != nil {
                return .blue
            }
            else {
                return .red
            }
        }
        else {
            return .red
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
            if selectedModel != nil {
                return "MANAGE MODELS"
            }
            else {
                return "SELECT A MODEL"
            }
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
