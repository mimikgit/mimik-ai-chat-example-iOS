//
//  ContentView+UI-Labels.swift
//

import Foundation
import SwiftUI

internal extension ContentView {
    
    func manageModelsIcon() -> String {
        
        if downloadedModels.isEmpty {
            return "gear.badge"
        }
        else {
            return "gear"
        }
    }
    
    func manageModelsFont() -> Font {
        if selectedModel != nil && downloadedModels.count >= 1 {
            .title3
        }
        else {
            .title
        }
    }
    
    func manageModelsColour() -> Color {
        
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
    
    func manageModelsBorderColour() -> Color {
        
        if downloadedModels.isEmpty || selectedModel == nil {
            return .clear
        }
        
        if isWaiting || activeStream != nil || activeNonStream != nil {
            return .red
        }
        
        return .blue
    }
    
    func manageModelsLabel() -> String {
        
        if downloadedModels.isEmpty {
            return "START HERE"
        }
        else {
            if let selectedModelId = selectedModel?.id {
                return selectedModelId
            }
            else {
                return "SELECT A MODEL"
            }
        }
    }
    
    func userInputPrompt() -> String {
        
        if activeStream != nil  {
            return "Streaming response"
        }
        
        if activeNonStream != nil {
            return "Waiting for non-streamed response."
        }
        
        if isWaiting {
            return "Model warmup. Please wait."
        }
        
        return downloadedModels.count >= 1 ? "Enter your question (context gets included)" : ""
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
