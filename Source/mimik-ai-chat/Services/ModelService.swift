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
    
    private(set) var primaryValidateService: EdgeClient.AI.ServiceConfiguration? {
        didSet { objectWillChange.send() }
    }
    
    var configuredServices: [EdgeClient.AI.ServiceConfiguration] = []
            
    init(engineService: EngineService, appState: AppState, authState: AuthState) {
        self.engineService = engineService
        self.appState = appState
        self.authState = authState
    }
    
    func configuredServices(sortedFirstBy preferredKind: EdgeClient.AI.ServiceConfiguration.Kind) -> [EdgeClient.AI.ServiceConfiguration] {
        return configuredServices.sorted { lhs, rhs in
            if lhs.kind == preferredKind && rhs.kind != preferredKind { return true }
            if lhs.kind != preferredKind && rhs.kind == preferredKind { return false }
            return lhs.id < rhs.id
        }
    }
        
    func reAuthorizeServices() {
        
        configuredServices = configuredServices.map { service in
            EdgeClient.AI.ServiceConfiguration(kind: service.kind, modelId: service.modelId, apiKey: authState.accessToken(serviceKind: service.kind, tokenType: .developerToken), mimOEPort: service.mimOEPort, mimOEClientId: service.mimOEClientId)
        }
        
        primaryValidateService = configuredServices.first {
            $0.kind == .gemini && ($0.apiKey?.isEmpty == false)
        }
        
        print("🟢 Reauthorized services. \nconfiguredServices:", configuredServices, "\nprimaryValidateService:", primaryValidateService?.kind.rawValue ?? "N/A")
    }
    
    // Integrates mimik ai use case from a configuration object.
    @MainActor
    public func integrateAI(useCase: EdgeClient.UseCase) async throws {
        
        guard let apiKey = ConfigService.fetchConfig(for: .milmApiKey) else {
            print("⚠️ API key error")
            showError(text: "API key error")
            throw NSError(domain: "API key error", code: 500)
        }
        
        appState.generalMessage = "Please Wait..."
                
        switch await engineService.edgeClient.integrateAI(accessToken: engineService.mimOEAccessToken, apiKey: apiKey, config: useCase, model: nil, downloadHandler: { download in
            
        }, requestHandler: { request in
            DispatchQueue.main.async {
                self.appState.activeStream = request
            }
        }) {
            
        case .success(let deployResult):
            appState.activeStream = nil
            engineService.deployedUseCase = deployResult
            authState.saveToken(token: apiKey, serviceKind: .mimikAI, tokenType: .developerToken)
            await processAvailableAIModels()
            
        case .failure(let error):
            print("⚠️ Integrate AI use case error", error.localizedDescription)
            appState.generalMessage = error.localizedDescription
            appState.activeStream = nil
            await processAvailableAIModels()
            throw error
        }
    }

    @MainActor
    public func processAvailableAIModels() async {
        
        guard let apiKey = ConfigService.fetchConfig(for: .milmApiKey), let useCase = engineService.deployedUseCase, case let .success(models) = await engineService.edgeClient.aiModels(accessToken: engineService.mimOEAccessToken, apiKey: apiKey, useCase: useCase), let firstModel = models.first else {
            appState.newResponse = ""
            appState.selectedModelId = ""
            appState.generalMessage = ""
            appState.downloadedModels = []
            appState.selectedModel = nil
            return
        }
        
        appState.downloadedModels = models
        
        for downloadedModel in appState.downloadedModels {
            print("🟢 Downloaded AI model \(downloadedModel.dictionary ?? [:])")
        }
        
        if models.count == 1 {
            print("✅ Selecting the first and only downloaded AI model automatically.")
            await selectActive(model: firstModel, automatic: true)
        }
        else if !appState.justDownloadedModelId.isEmpty {
            guard let model = appState.downloadedModels.first(where: { $0.id == appState.justDownloadedModelId }) else {
                print("⚠️ Unable to find the model that just downloaded")
                return
            }
            
            print("✅ Selecting the just downloaded model \(appState.justDownloadedModelId) automatically.")
                        
            Task {
                appState.generalMessage = "Please Wait..."
                await selectActive(model: model, automatic: false)
                appState.generalMessage = "Active model changed to <\(model.id ?? "")>"
                try await Task.sleep(nanoseconds: 5_000_000_000)
                resetGeneralMessage()
            }
        }
        else {
            if let model = appState.downloadedModels.first {
                print("⚠️ Multiple (\(appState.downloadedModels.count)) AI models downloaded. Selecting first one automatically.")
                await selectActive(model: model, automatic: false)
            }
        }
    }
        
    @MainActor
    public func selectActive(model: EdgeClient.AI.Model, automatic: Bool) async {
        appState.selectedModel = model
        
        guard let modelId = appState.selectedModel?.id else {
            return
        }
        
        appState.selectedModelId = "\(modelId)"
        appState.generalMessage = ""
        appState.resetContextState()
    }
    
    @MainActor
    public func deleteAIModel(id: String) async throws {
        
        guard let apiKey = ConfigService.fetchConfig(for: .milmApiKey), let useCase = engineService.deployedUseCase else {
            print("⚠️ API key error")
            showError(text: "API key error")
            throw NSError(domain: "API key error", code: 500)
        }
                
        switch await engineService.edgeClient.deleteAIModel(id: id, accessToken: engineService.mimOEAccessToken, apiKey: apiKey, useCase: useCase) {
            
        case .success:
            appState.generalMessage = "\(id) deleted"
            await processAvailableAIModels()
            print("success")
        case .failure(let error):
            showError(text: error.domain)
            await processAvailableAIModels()
            print("error: \(error.localizedDescription)")
            throw error
        }
    }
    
    public var infoMessage: String {
        guard appState.generalMessage.isEmpty else {
            return appState.generalMessage
        }
        return defaultMessage
    }

    public func resetGeneralMessage() {
        guard !appState.downloadedModels.isEmpty else {
            appState.generalMessage = ""
            return
        }
        appState.generalMessage = defaultMessage
    }

    private var defaultMessage: String {
        
        guard let kind = appState.selectedModel?.kind else {
            return ""
        }
        
        let modelId = appState.selectedModelId
        switch kind {
        case .llm:
            let question = "Ask <\(modelId)> a question"
            if let gemini = primaryValidateService {
                return "\(question).\n<\(gemini.modelId)> will validate it."
            } else {
                return "\(question). You can follow up in the same context."
            }

        case .vlm:
            return "Attach an image and ask <\(modelId)> to describe it."
        @unknown default:
            return ""
        }
    }
    
    internal func showError(text: String) {
        appState.activeStream?.cancel()
        appState.activeStream = nil
        appState.resetContextState()
        print("⚠️ Show error:", text)
    }
}
