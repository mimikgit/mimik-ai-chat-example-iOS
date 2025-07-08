//
//  ModelService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-02.
//

import EdgeCore
import SwiftUI

extension ModelService {
    
    @MainActor
    public func availableModels(configuration: EdgeClient.AI.ServiceConfiguration) async throws {
                
        appState.generalMessage = "Contacting \(configuration.id) for available models. Please Wait..."
             
        let promptMessage = EdgeClient.AI.Model.Message(role: "user", content: "\(configuration.kind.rawValue): List available models", modelId: configuration.modelId)
        postUserPrompt(message: promptMessage)
        
        let client: any EdgeClient.AI.ServiceInterface = EdgeClient.AI.HybridClient(configuration: configuration)
        let result = await client.availableModelsMessage()

        switch result {
        case .success(let response):
            print("✅ \(configuration.id) Response:\n\(response)")
            ongoingStreamResponse(message: response)
            
            appState.newResponse = ""
            appState.activeStream = nil
            appState.generalMessage = ""
                        
        case .failure(let error):
            print("❌ Error: \(error.localizedDescription)")
            showError(text: error.domain)
            throw error
        }
    }
}
