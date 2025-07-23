//
//  ModelService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-02.
//

import EdgeCore
import SwiftUI

class ModelService: ObservableObject {
    
    @ObservedObject var engineService: EngineService
    @ObservedObject var appState: AppState
    @ObservedObject var authState: AuthState
    
    @Published var downloadedModels: [EdgeClient.AI.Model] = []
    
    enum ServiceType {
        case prompt
        case validation
    }
    
    var mimikAiConfiguration: EdgeClient.AI.ServiceConfiguration? {
        guard let milmApiKey = ConfigService.fetchConfig(for: .milmApiKey), let mimOEPort = engineService.edgeClient.edgeEngineFullPathUrl().port else {
            return nil
        }
        return EdgeClient.AI.ServiceConfiguration(kind: .mimikAI, model: nil, apiKey: milmApiKey, mimOEPort: mimOEPort, mimOEClientId: engineService.mimOEClientId)
    }

    var geminiAiConfiguration: EdgeClient.AI.ServiceConfiguration? {
        let model = EdgeClient.AI.Model.init(id: "gemini-2.0-flash", kind: .llm)
        return EdgeClient.AI.ServiceConfiguration(kind: .gemini, model: model, apiKey: nil, mimOEPort: nil, mimOEClientId: nil)
    }
    
    @Published var configuredServices: [EdgeClient.AI.ServiceConfiguration] = []
    @Published var selectedPromptService: EdgeClient.AI.ServiceConfiguration? = nil
    @Published var selectedValidateService: EdgeClient.AI.ServiceConfiguration? = nil
                
    init(engineService: EngineService, appState: AppState, authState: AuthState) {
        self.engineService = engineService
        self.appState = appState
        self.authState = authState
    }
    
    // Integrates mimik AI service from a configuration object.
    @MainActor
    func integrateAIService(useCase: EdgeClient.UseCase) async throws {
        
        guard let apiKey = ConfigService.fetchConfig(for: .milmApiKey) else {
            print("⚠️ API key error")
            showError(text: "API key error")
            throw NSError(domain: "API key error", code: 500)
        }
                        
        switch await engineService.edgeClient.integrateAIService(accessToken: engineService.mimOEAccessToken, apiKey: apiKey, useCase: .inline(useCase)) {
            
        case .success(let deployResult):
            print("✅ Integrate AI use case success", deployResult)
            engineService.deployedUseCase = deployResult.useCase
            authState.saveToken(token: apiKey, serviceKind: .mimikAI, tokenType: .developerToken)
            await updateConfiguredServices()
            
        case .failure(let error):
            print("⚠️ Integrate AI use case error", error.localizedDescription)
            appState.generalMessage = error.localizedDescription
            await updateConfiguredServices()
            throw error
        }
    }
    
    var infoMessage: String {
        guard appState.generalMessage.isEmpty else {
            return appState.generalMessage
        }
        return defaultMessage
    }
    
    func stateReset() {
        print("⚠️ Clear ModelService state")
        selectedPromptService = nil
        selectedValidateService = nil
        configuredServices.removeAll()
    }

    func resetGeneralMessage() {
        guard selectedPromptService != nil else {
            appState.generalMessage = ""
            return
        }
        appState.generalMessage = defaultMessage
    }
    
    func showError(text: String) {
        appState.stateReset()
        print("⚠️ Show error:", text)
    }

    private var defaultMessage: String {
        
        guard let kind = selectedPromptService?.model?.kind, let modelId = selectedPromptService?.model?.id else {
            return ""
        }
        
        switch kind {
        case .llm:
            let question = "Ask <\(modelId)> a question"
            if let modelId = selectedValidateService?.modelId {
                return "\(question).\n<\(modelId)> will validate it."
            } else {
                return "\(question). You can follow up in the same context."
            }

        case .vlm:
            return "Attach an image and ask <\(modelId)> to describe it."
        @unknown default:
            return ""
        }
    }
}
