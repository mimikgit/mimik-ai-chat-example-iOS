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
    @ObservedObject var appState: StateService
  
    init(engineService: EngineService, appState: StateService) {
        self.engineService = engineService
        self.appState = appState
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
            await processAvailableAIModels()
            
        case .failure(let error):
            print("⚠️ Integrate AI use case error", error.localizedDescription)
            appState.generalMessage = error.localizedDescription
            appState.activeStream = nil
            await processAvailableAIModels()
            throw error
        }
    }

    // Asks AI model a question and receives a stream of responses in the stream handler. Request handler provides a reference to the stream.
    @MainActor
    public func chatAIStream(question: String) async throws {
                
        guard let selectedModelId = appState.selectedModel?.id, let useCase = engineService.deployedUseCase, let apiKey = ConfigService.fetchConfig(for: .milmApiKey) else {
            print("⚠️ AI use case error")
            appState.generalMessage = "Error"
            throw NSError(domain: "Error", code: 500)
        }
                
        appState.generalMessage = "Please Wait..."
             
        let message = EdgeClient.AI.Model.Message(role: "user", content: question)
        postUserQuestion(message: message)
        
        let request = EdgeClient.AI.Model.ChatRequest(modelId: selectedModelId, accessToken: engineService.mimOEAccessToken, apiKey: apiKey, question: message, useCase: useCase, context: appState.postedMessages, temperature: 0.1)
        
        switch await engineService.edgeClient.chatAI(request: request, streamHandler: { stream in
            
            switch stream {
            case .success(let result):
                self.processIncomingData(stream: result)
            case .failure(let error):
                self.showError(text: error.domain)
            }
            
        }, requestHandler: {
            request in
            DispatchQueue.main.async {
                self.appState.activeStream = request
            }
        }) {
        case .success:
            print("✅", #function, #line)
            appState.newResponse = ""
            appState.activeStream = nil
        case .failure(let error):
            showError(text: error.domain)
            throw error
        }
    }
    
    // Asks a vision AI model a question about an uploaded image and receives a stream of responses in the stream handler. Request handler provides a reference to the stream.
    @MainActor
    public func visionAIStream(question: String, image: UIImage) async throws {
                
        guard let selectedModelId = appState.selectedModel?.id, let useCase = engineService.deployedUseCase, let apiKey = ConfigService.fetchConfig(for: .milmApiKey) else {
            print("⚠️ AI use case error")
            appState.generalMessage = "Error"
            throw NSError(domain: "Error", code: 500)
        }
        
        appState.generalMessage = "Please Wait..."
        
        let message = EdgeClient.AI.Model.Message(role: "user", content: question)
        let resizeImgOptions = EdgeClient.ImageResizeOptions(size: CGSize.init(width: 500, height: 500), compressionQuality: 0.5, bytesLimit: 100_000)
        postUserQuestion(message: message, image: image, resizeImgOptions: resizeImgOptions)
        
        let request = EdgeClient.AI.Model.ChatRequest(modelId: selectedModelId, accessToken: engineService.mimOEAccessToken, apiKey: apiKey, question: message, useCase: useCase, context: [], temperature: 0.1)
        
        switch await engineService.edgeClient.visionAI(request: request, image: image, resizeImgOptions: resizeImgOptions, streamHandler: { stream in
            
            switch stream {
            case .success(let result):
                self.processIncomingData(stream: result)
            case .failure(let error):
                self.showError(text: error.domain)
            }
            
        }, requestHandler: {
            request in
            DispatchQueue.main.async {
                self.appState.activeStream = request
            }
        }) {
        case .success:
            appState.newResponse = ""
            appState.activeStream = nil
            appState.selectedImage = nil
            appState.selectedFileURL = nil
        case .failure(let error):
            showError(text: error.domain)
            throw error
        }
    }
    
    // Processes ready to use AI models residing locally on the user device.
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
                appState.resetGeneralMessage()
            }
        }
        else {
            if let model = appState.downloadedModels.first {
                print("⚠️ Multiple (\(appState.downloadedModels.count)) AI models downloaded. Selecting first one automatically.")
                await selectActive(model: model, automatic: false)
            }
        }
    }
        
    // Selects an AI model to be the primary, active model.
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
    
    // Deletes a downloaded AI model.
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
    
    // Adds user's prompt to the posted messages array.
    private func postUserQuestion(message: EdgeClient.AI.Model.Message, image: UIImage? = nil, resizeImgOptions: EdgeClient.ImageResizeOptions? = nil) {
        print(">>> 1",#function,  message.content ?? "", "role:", message.role ?? "")
        
        if let image = image, let resizeImgOptions = resizeImgOptions, let resizedImage = image.resizeImage(targetSize: resizeImgOptions.size, bytesLimit: resizeImgOptions.bytesLimit, compressionQuality: resizeImgOptions.compressionQuality), let imageBase64String = resizedImage.base64FromJpeg(compressionQuality: 0.5) {
            let newMessageWithImage = EdgeClient.AI.Model.Message(role: message.role, content: message.content, thumbnailBase64: imageBase64String)
            appState.postedMessages.append(newMessageWithImage)
        }
        else {
            appState.postedMessages.append(message)
        }
    }
    
    // Processes incoming AI model data, shows appropriate UI prompts based on the type.
    private func processIncomingData(stream: EdgeClient.AI.Model.CompletionType) {
        switch stream {
        case .content(let content):
            
            guard let message = content.content else {
                print("⚠️", "Error: No content")
                return
            }
            
            if appState.newResponse.contains("Model Ready") || appState.newResponse.contains("Model Loading") {
                appState.newResponse = message
                return
            }
            
            ongoingStreamResponse(message: content)
            appState.newResponse = appState.newResponse + message
        case .modelLoading:
            appState.newResponse = "Model Loading, please wait"
        case .modelReady:
            appState.newResponse = "Model Ready, please wait"
        case .modelProcessing:
            appState.newResponse = "Model Processing, please wait"
        case .streamDone(let usage):
            if let usage = usage {
                appState.lastTokenUsage = usage
            }
        case .comment, .event, .id, .retry:
            print("Other model response data")
        case .error(let errorDomain, let statusCode):
            print("Model response data error:", errorDomain, statusCode)
        @unknown default:
            print("Unknown model response data")
        }
    }

    // Processes currently active stream of model responses into a human readable format.
    private func ongoingStreamResponse(message: EdgeClient.AI.Model.Message) {
        
        guard message.role != nil, let content = message.content, let lastMessage = appState.postedMessages.last else {
            print("⚠️ No message content to process")
            return
        }
                
        if lastMessage.isUserType {
            appState.postedMessages.append(message)
        }
        else if lastMessage.isAiType, let lastContent = lastMessage.content {
            appState.postedMessages.removeLast()
            let newContent = lastContent + content
            appState.postedMessages.append(EdgeClient.AI.Model.Message(role: message.role, content: newContent, thumbnailBase64: nil))
        }
        else {
            print("⚠️ Unsupported message content")
        }
    }
    
    private func showError(text: String) {
        appState.activeStream?.cancel()
        appState.activeStream = nil
        appState.resetContextState()
        print("⚠️ Show error:", text)
    }
}
