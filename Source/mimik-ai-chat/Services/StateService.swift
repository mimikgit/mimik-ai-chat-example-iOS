//
//  AppState.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-01.
//

import Alamofire
import EdgeCore
import SwiftUI

class AppState: ObservableObject {
    
    @Published var selectedModel: EdgeClient.AI.Model?
    @Published var selectedModelId: String = ""
    
    // Track which service was selected for token input
    @Published var tokenInputService: EdgeClient.AI.ServiceConfiguration?
    
    // Holds the token input the user types in
    @Published var developerToken: String = ""
    
    @Published var downloadedModels: [EdgeClient.AI.Model] = []
    @Published var postedMessages: [EdgeClient.AI.Model.Message] = []
    @Published var justDownloadedModelId: String = ""
    @Published var generalMessage: String = ""
    @Published var tokenUsage: [String: EdgeClient.AI.Model.Usage] = [:]
    @Published var newResponse: String = ""

    // Active model response stream
    @Published var activeStream: DataStreamRequest?    
    @Published var activeProtocolStream: EdgeClient.AI.CancellableStream<EdgeClient.AI.Model.CompletionResponse>?
    
    // Photo Picker selection
    @Published var selectedImage: UIImage?
    
    // File Picker selection
    @Published var selectedFileURL: URL? = nil
        
    func resetContextState() {
        print("⚠️ Resets context state and cancels any active streams")
        postedMessages = []
        justDownloadedModelId = ""
        generalMessage = ""
        tokenUsage = [:]
        activeStream?.cancel()
        activeStream = nil
        selectedImage = nil
        selectedFileURL = nil
        activeProtocolStream.map { $0.cancel() }
    }
    
    func stateReset() {
        print("⚠️ Clear AppState, reset")
        selectedModel = nil
        downloadedModels.removeAll()
        resetContextState()
    }
    
    public func alreadyDownloadedModel(id: String) -> Bool {        
        for model in downloadedModels {
            if let modelId = model.id, modelId == id {
                return true
            }
        }
        return false
    }
    
    public func messagesForCopying(includePrompt: Bool = true) -> String {
        var result: [String] = []
        for message in postedMessages {
            if let content = message.content {
                if message.isUserType, includePrompt {
                    result.append("\nPrompt: \(content)")
                } else if message.isAiType {
                    result.append("Response: \(content)")
                }
            }
        }
        return result.joined(separator: "\n")
    }
}
