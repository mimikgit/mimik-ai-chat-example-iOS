//
//  StateService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-01.
//

import Alamofire
import EdgeCore
import SwiftUI

class StateService: ObservableObject {
    
    @Published var selectedModel: EdgeClient.AI.Model?
    @Published var downloadedModels: [EdgeClient.AI.Model] = []
    @Published var postedMessages: [EdgeClient.AI.Model.Message] = []
    @Published var justDownloadedModelId: String = ""
    
    @Published var generalMessage: String = ""
    @Published var performanceMessage: String = ""
    @Published var lastTokenUsage: EdgeClient.AI.Model.Usage?
    
    @Published var newResponse: String = ""
    @Published var selectedModelId: String = ""
    
    // Active model response stream
    @Published var activeStream: DataStreamRequest?
    
    // Photo Picker selection
    @Published var selectedImage: UIImage?
    
    // File Picker selection
    @Published var selectedFileURL: URL? = nil
    
    func resetContextState() {
        print("⚠️ Resets context state and cancels any active streams")
        postedMessages = []
        justDownloadedModelId = ""
        generalMessage = ""
        performanceMessage = ""
        lastTokenUsage = nil
        activeStream?.cancel()
        activeStream = nil
        selectedImage = nil
        selectedFileURL = nil
    }
    
    func stateReset() {
        print("⚠️ Clear StateService, reset")
        selectedModel = nil
        downloadedModels.removeAll()
        resetContextState()
    }
    
    public var infoMessage: String {
        if !performanceMessage.isEmpty {
            return performanceMessage
        }
        
        if !generalMessage.isEmpty {
            return generalMessage
        }
        
        return selectedModel?.kind == .llm ? "Ask <\(selectedModelId)> a question. Then follow up in the same context." : "Attach an image and ask <\(selectedModelId)> to describe it."
    }
    
    public func resetGeneralMessage() {
        if downloadedModels.isEmpty {
            generalMessage = ""
            return
        }
        
        generalMessage = selectedModel?.kind == .llm ? "Ask <\(selectedModelId)> a question. Then follow up in the same context." : "Attach an image and ask <\(selectedModelId)> to describe it."
    }
    
    public func alreadyDownloadedModel(id: String) -> Bool {        
        for model in downloadedModels {
            if let modelId = model.id, modelId == id {
                return true
            }
        }
        return false
    }
}
