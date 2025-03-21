//
//  ContentView+AI.swift
//

import Alamofire
import EdgeCore
import Foundation
import SwiftyJSON

extension ContentView {
    
    /// Integrates mimik ai use case using a configuration url. Optionally, also downloads an AI model locally to the user device as part of the integration.
    func integrateAI(useCase: EdgeClient.UseCase, model: EdgeClient.AI.Model.CreateModelRequest?) async -> Result<Bool, NSError> {
        
        guard let apiKey = ConfigManager.fetchConfig(for: .milmApiKey) else {
            print("⚠️ API key error")
            showError(text: "API key error")
            return .failure(NSError(domain: "API key error", code: 500))
        }
                
        switch await self.edgeClient.integrateAI(accessToken: mimOEAccessToken, apiKey: apiKey, config: useCase, model: model, downloadHandler: { download in
            
            guard case let .success(downloadProgress) = download else {
                print("⚠️ Model download error")
                activeStream = nil
                activeNonStream = nil
                showError(text: "Model download error")
                return
            }
            
            let percent = String(format: "%.2f", ceil( (downloadProgress.size / downloadProgress.totalSize) * 10_000) / 100)
            let line = "Model download progress: " + "\(percent)％ \nDon't lock your device.\nKeep this app open."
            print("⚠️ Model download progress: " + percent)
            
            if line.contains("100.00") {
                justDownloadedModelId = model?.id
            }
            else {
                bottomMessage = line
                justDownloadedModelId = nil
            }
            
        }, requestHandler: { request in
            activeStream = request
        }) {
            
        case .success(let deployResult):
            activeStream = nil
            
            guard let encoded = try? JSONEncoder().encode(deployResult) else {
                let message = "⚠️ Integrate AI use case encoding error"
                bottomMessage = message
                return .failure(NSError(domain: message, code: 500))
            }
            
            // Storing use case deployment information in UserDefaults
            UserDefaults.standard.set(encoded, forKey: kAIUseCaseDeployment)
            UserDefaults.standard.synchronize()
            
            print("✅ Integrate AI use case success")
            return .success(true)
            
        case .failure(let error):
            print("⚠️ Integrate AI use case error", error.localizedDescription)
            bottomMessage = error.localizedDescription
            activeStream = nil
            return .failure(error)
        }
    }

    /// Asks AI model a question and receives a stream of responses in the stream handler. Request handler provides a reference to the stream.
    func chatAIStream(question: String) async -> Result<Any, NSError> {
                
        guard let selectedModelId = selectedModel?.id, let useCase = deployedUseCase, let apiKey = ConfigManager.fetchConfig(for: .milmApiKey) else {
            print("⚠️ AI use case error")
            storedResponse = "Error"
            return .failure(NSError.init(domain: "Error", code: 500))
        }
             
        isWaiting = true
        
        let message = EdgeClient.AI.Model.Message(role: "user", content: question)
        storeLiveContent(message: message)
        storeCombinedContext(message: message)
        
        let request = EdgeClient.AI.Model.ChatRequest(modelId: selectedModelId, accessToken: mimOEAccessToken, apiKey: apiKey, question: message, useCase: useCase, context: storedCombinedContext, temperature: 0.1)
        
        switch await edgeClient.chatAI(request: request, streamHandler: { stream in
            
            switch stream {
            case .success(let result):
                processIncomingData(stream: result)
            case .failure(let error):
                showError(text: error.domain)
            }
            
        }, requestHandler: {
            request in
            activeStream = request
        }) {
        case .success(let completion):
            print("✅", #function, #line)
            storedResponse = storedResponse + newResponse
            storeCombinedContext(message: EdgeClient.AI.Model.Message(role: "assistant", content: newResponse))
            newResponse = ""
            isWaiting = false
            activeStream = nil
            return .success(completion)
        case .failure(let error):
            showError(text: error.domain)
            return .failure(error)
        }
    }
    
    func chatAIDirect(question: String) async -> Result<Any, NSError> {
                
        guard let selectedModelId = selectedModel?.id, let useCase = deployedUseCase, let apiKey = ConfigManager.fetchConfig(for: .milmApiKey) else {
            print("⚠️ AI use case error")
            storedResponse = "Error"
            return .failure(NSError.init(domain: "Error", code: 500))
        }
             
        isWaiting = true
        
        let message = EdgeClient.AI.Model.Message(role: "user", content: question)
        storeLiveContent(message: message)
        storeCombinedContext(message: message)
        
        let request = EdgeClient.AI.Model.ChatRequest(modelId: selectedModelId, accessToken: mimOEAccessToken, apiKey: apiKey, question: message, useCase: useCase, context: storedCombinedContext, temperature: 0.1)
        
        switch await edgeClient.chatAI(request: request, requestHandler: { request in
            activeNonStream = request
        }) {
        case .success(let content):
            
            guard let message = content.choices?.first?.message, let messageContent = message.content else {
                print("⚠️", #function, #line, "empty content")
                return .success("empty content")
            }
            
            storedResponse = storedResponse + messageContent
            storeLiveContent(message: message)
            storeCombinedContext(message: message)
            newResponse = ""
            isWaiting = false
            activeNonStream = nil
            
            if let usage = content.usage {
                lastUsage = usage
            }
            
            return .success(content)
        case .failure(let error):
            showError(text: error.domain)
            return .failure(error)
        }
    }
    
    func warmUpAI() async -> Result<Void, NSError> {
        
        guard let selectedModelId = selectedModel?.id, let useCase = deployedUseCase, let apiKey = ConfigManager.fetchConfig(for: .milmApiKey) else {
            print("⚠️ AI use case error")
            storedResponse = "Error"
            return .failure(NSError.init(domain: "Error", code: 500))
        }
             
        isWaiting = true
        
        let request = EdgeClient.AI.Model.WarmupRequest(modelId: selectedModelId, accessToken: mimOEAccessToken, apiKey: apiKey, useCase: useCase)
        switch await edgeClient.warmUpAI(request: request) {
        case .success(let content):
            isWaiting = false
            return .success(content)
        case .failure(let error):
            showError(text: error.domain)
            return .failure(error)
        }
    }
    
    func visualAIStream(question: String, image: UIImage) async -> Result<Any, NSError> {
                
        guard let selectedModelId = selectedModel?.id, let useCase = deployedUseCase, let apiKey = ConfigManager.fetchConfig(for: .milmApiKey) else {
            print("⚠️ AI use case error")
            storedResponse = "Error"
            return .failure(NSError.init(domain: "Error", code: 500))
        }
        
        isWaiting = true
        
        let message = EdgeClient.AI.Model.Message(role: "user", content: question)
        storeLiveContent(message: message)
        storeCombinedContext(message: message)
        
        let request = EdgeClient.AI.Model.ChatRequest(modelId: selectedModelId, accessToken: mimOEAccessToken, apiKey: apiKey, question: message, useCase: useCase, context: [], temperature: 0.1)
        
        let resizeImage = EdgeClient.ImageResizeOptions(size: CGSize.init(width: 500, height: 500), compressionQuality: 0.5, bytesLimit: 100_000)
        
        switch await edgeClient.visionAI(request: request, image: image, resizeImage: resizeImage, streamHandler: { stream in
            
            switch stream {
            case .success(let result):
                processIncomingData(stream: result)
            case .failure(let error):
                showError(text: error.domain)
            }
            
        }, requestHandler: {
            request in
            activeStream = request
        }) {
        case .success(let completion):
            print("✅", #function, #line)
            storedResponse = storedResponse + newResponse
            storeCombinedContext(message: EdgeClient.AI.Model.Message(role: "assistant", content: newResponse))
            newResponse = ""
            isWaiting = false
            activeStream = nil
            selectedImage = nil
            selectedFileURL = nil
            return .success(completion)
        case .failure(let error):
            showError(text: error.domain)
            return .failure(error)
        }
    }
    
    /// Processes ready to use AI models residing locally on the user device.
    func processAvailableAIModels() async {
        
        guard let apiKey = ConfigManager.fetchConfig(for: .milmApiKey), let useCase = deployedUseCase, case let .success(models) = await edgeClient.aiModels(accessToken: mimOEAccessToken, apiKey: apiKey, useCase: useCase), let firstModel = models.first else {
            storedResponse = ""
            newResponse = ""
            selectedModelId = ""
            bottomMessage = ""
            downloadedModels = []
            selectedModel = nil
            return
        }
        
        downloadedModels = models
        
        for downloadedModel in self.downloadedModels {
            print("🟢 Downloaded AI model \(downloadedModel.dictionary ?? [:])")
        }
        
        if models.count == 1 {
            print("✅ Selecting the first and only downloaded AI model automatically.")
            await selectActive(model: firstModel, automatic: true)
        }
        else if let justDownloadedModelId = justDownloadedModelId {
            guard let model = downloadedModels.first(where: { $0.id == justDownloadedModelId }) else {
                print("⚠️ Multiple (\(downloadedModels.count)) AI models downloaded. Unable to select one automatically.")
                return
            }
            
            print("✅ Selecting the just downloaded model \(justDownloadedModelId) automatically.")
            await selectActive(model: model, automatic: true)
            showSwitchModel = true
        }
        else {
            print("⚠️ Multiple (\(downloadedModels.count)) AI models downloaded. Unable to select one automatically.")
        }
    }
        
    /// Selects an AI model to be the primary, active model.
    func selectActive(model: EdgeClient.AI.Model, automatic: Bool) async {
        selectedModel = model
        
        guard let modelId = selectedModel?.id else {
            return
        }
        
        selectedModelId = "\(modelId)"
        bottomMessage = ""
        clearContext()
    }
    
    /// Processes incoming AI model data, shows appropriate UI prompts based on the type.
    fileprivate func processIncomingData(stream: EdgeClient.AI.Model.CompletionType) {
        switch stream {
        case .content(let content):
            
            guard let message = content.content else {
                print("⚠️", "Error: No content")
                return
            }
            
            if newResponse.contains("Model Ready") || newResponse.contains("Model Loading") {
                newResponse = message
                return
            }
            
            storeLiveContent(message: content)
            newResponse = newResponse + message
        case .modelLoading:
            newResponse = "Model Loading, please wait"
        case .modelReady:
            newResponse = "Model Ready, please wait"
        case .modelProcessing:
            newResponse = "Model Processing, please wait"
        case .streamDone(let usage):
            if let usage = usage {
                lastUsage = usage
            }
        case .comment, .event, .id, .retry:
            print("other")
        case .error(let errorDomain, let statusCode):
            print("error:", errorDomain, statusCode)
        @unknown default:
            print("unknown")
        }
    }
    
    fileprivate func storeLiveContent(message: EdgeClient.AI.Model.Message) {
//        print(">>> ", message.content ?? "")
        storedLiveContent.append(message)
    }
    
    fileprivate func storeCombinedContext(message: EdgeClient.AI.Model.Message) {
        storedCombinedContext.append(message)
    }
    
    func contextForCall() -> [EdgeClient.AI.Model.Message]? {
        return []
    }
    
    func clearContext() {
        storedLiveContent = []
        storedCombinedContext = []
        newResponse = ""
        storedResponse = ""
        bottomMessage = ""
        activeStream?.cancel()
        activeNonStream?.cancel()
        selectedImage=nil
    }
    
    /// Shows a user facing error in the UI.
    fileprivate func showError(text: String) {
        storedResponse = storedResponse + "\n\n[\(text)]\n[Stored context cleared]"
        isWaiting = false
        activeStream = nil
        activeNonStream = nil
        clearContext()
        print("⚠️ showError:", text)
    }
    
    /// Deletes a downloaded AI languahe model.
    func deleteAIModel(id: String) async -> Result<Void, NSError> {
        
        guard let apiKey = ConfigManager.fetchConfig(for: .milmApiKey), let useCase = deployedUseCase else {
            print("⚠️ API key error")
            showError(text: "API key error")
            return .failure(NSError(domain: "API key error", code: 500))
        }
                
        switch await edgeClient.deleteAIModel(id: id, accessToken: mimOEAccessToken, apiKey: apiKey, useCase: useCase) {
            
        case .success:
            bottomMessage = "\(id) deleted"
            await processAvailableAIModels()
            return .success(())
        case .failure(let error):
            showError(text: error.domain)
            await processAvailableAIModels()
            return .failure(error)
        }
    }
}
