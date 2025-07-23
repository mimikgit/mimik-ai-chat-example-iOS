//
//  ModelService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-02.
//

import EdgeCore
import SwiftUI

extension ModelService {
    
    func alreadyDownloadedModel(id: String) -> Bool {
        for model in downloadedModels {
            if let modelId = model.id, modelId == id {
                return true
            }
        }
        return false
    }
    
    @MainActor
    func updateDownloadedModels() async throws {
        
        guard let configuration = mimikAiConfiguration else {
            print("❌ downloadedModels Error")
            return
        }
                     
        let client: any EdgeClient.AI.ServiceInterface = EdgeClient.AI.HybridClient(configuration: configuration, hybridEdgeClient: self.engineService.hybridEdgeClient)
        let result = await client.availableModels()
        
        switch result {
        case .success(let response):            
            let readyModels = response.filter { $0.readyToUse ?? true }
            downloadedModels = readyModels
            print("✅", #function, downloadedModels)
                        
        case .failure(let error):
            print("❌ downloadedModels Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func availableModels(configuration: EdgeClient.AI.ServiceConfiguration) async throws {
                
        appState.generalMessage = "Contacting \(configuration.id) for available models. Please Wait..."
             
        let promptMessage = EdgeClient.AI.Model.Message(role: "user", content: "\(configuration.kind.rawValue): List available models", modelId: configuration.modelId)
        postUserPrompt(message: promptMessage)
        
        let client: any EdgeClient.AI.ServiceInterface = EdgeClient.AI.HybridClient(configuration: configuration, hybridEdgeClient: self.engineService.hybridEdgeClient)
        let result = await client.availableModelsMessage()

        switch result {
        case .success(let response):
            print("✅ \(configuration.id) Response:\n\(response)")
            ongoingStreamResponse(message: response)
            
            appState.newResponse = ""
            appState.generalMessage = ""
                        
        case .failure(let error):
            print("❌ Error: \(error.localizedDescription)")
            showError(text: error.domain)
            throw error
        }
    }
    
    @MainActor
    func deleteAIModel(id: String) async throws {
        
        guard let apiKey = ConfigService.fetchConfig(for: .milmApiKey), let useCase = engineService.deployedUseCase else {
            print("⚠️ API key error")
            showError(text: "API key error")
            throw NSError(domain: "API key error", code: 500)
        }
                
        switch await engineService.edgeClient.deleteAIModel(id: id, accessToken: engineService.mimOEAccessToken, apiKey: apiKey, useCase: useCase) {
            
        case .success:
            appState.generalMessage = "\(id) deleted"
            await updateConfiguredServices()
            clearSelectionIfNeeded(matching: id)
            print("✅", #function, id)
        case .failure(let error):
            showError(text: error.domain)
            await updateConfiguredServices()
            clearSelectionIfNeeded(matching: id)
            print("⚠️ error: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func clearSelectionIfNeeded(matching id: String) {
        if selectedPromptService?.model?.id == id {
            selectedPromptService = nil
        }
        if selectedValidateService?.model?.id == id {
            selectedValidateService = nil
        }
    }
}
