//
//  ContentView+AI.swift
//

import Alamofire
import EdgeCore
import Foundation
import SwiftyJSON

extension ContentView {
    
    /// Integrates mimik ai use case using a configuration url. Optionally, also downloads an AI model locally to the user device as part of the integration.
    func integrateAI(useCaseConfigUrl: String, model: EdgeClient.AI.Model.CreateModelRequest?) async -> Result<Bool, NSError> {
        
        guard let apiKey = LoadConfig.mimikAIUseApiKey() else {
            print("⚠️ API key error")
            showError(text: "API key error")
            return .failure(NSError(domain: "API key error", code: 500))
        }
                
        switch await self.edgeClient.integrateAI(accessToken: mimOEAccessToken, apiKey: apiKey, configUrl: useCaseConfigUrl, model: model, downloadHandler: { download in
            
            guard case let .success(downloadProgress) = download else {
                print("⚠️ Model download error")
                activeStream = nil
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
                menuLabel = line
                justDownloadedModelId = nil
            }
            
        }, requestHandler: { request in
            activeStream = request
        }) {
            
        case .success(let deployResult):
            activeStream = nil
            
            // Storing use case deployment information in UserDefaults
            if let encoded = try? JSONEncoder().encode(deployResult) {
                UserDefaults.standard.set(encoded, forKey: kAIUseCaseDeployment)
                UserDefaults.standard.synchronize()
            }
            
            print("✅ Integrate AI use case success")
            return .success(true)
            
        case .failure(let error):
            print("⚠️ Integrate AI use case error", error.localizedDescription)
            menuLabel = error.localizedDescription
            activeStream = nil
            return .failure(error)
        }
    }

    /// Asks AI model a question and receives a stream of responses in the stream handler. Request handler provides a reference to the stream.
    func askAI(question: String) async -> Result<Any, NSError> {
                
        guard let selectedModelId = selectedModel?.id, let useCase = deployedUseCase, let apiKey = LoadConfig.mimikAIUseApiKey() else {
            print("⚠️ AI use case error")
            response = "Error"
            return .failure(NSError.init(domain: "Error", code: 500))
        }
             
        isWaiting = true
        
        switch await edgeClient.askAI(modelId: selectedModelId, accessToken: mimOEAccessToken, apiKey: apiKey, question: question, useCase: useCase, streamHandler: { stream in
            
            switch stream {
            case .success(let result):
                processIncomingData(stream: result)
            case .failure(let error):
                showError(text: error.localizedDescription)
            }
            
        }, requestHandler: {
            request in
            activeStream = request
        }) {
        case .success(let completion):
            isWaiting = false
            activeStream = nil
            return .success(completion)
        case .failure(let error):
            showError(text: error.localizedDescription)
            return .failure(error)
        }
    }
    
    /// Processes ready to use AI models residing locally on the user device.
    func processAvailableAIModels() async {
        
        guard let apiKey = LoadConfig.mimikAIUseApiKey(), let useCase = deployedUseCase, case let .success(models) = await edgeClient.aiModels(accessToken: mimOEAccessToken, apiKey: apiKey, useCase: useCase), let firstModel = models.first else {
            question = ""
            questionLabel = ""
            userInput = ""
            response = ""
            responseLabel1 = ""
            responseLabel2 = ""
            menuLabel = ""
            return
        }
        
        downloadedModels = models
        
        if models.count == 1 {
            print("✅ Selecting the first and only downloaded AI model automatically.")
            selectActive(model: firstModel, automatic: true)
        }
        else if let justDownloadedModelId = justDownloadedModelId {
            guard let model = downloadedModels.first(where: { $0.id == justDownloadedModelId }) else {
                print("⚠️ Multiple (\(downloadedModels.count)) AI models downloaded. Unable to select one automatically.")
                return
            }
            
            print("✅ Selecting the just downloaded model \(justDownloadedModelId) automatically.")
            selectActive(model: model, automatic: true)
            showSwitchModel = true
        }
        else {
            print("⚠️ Multiple (\(downloadedModels.count)) AI models downloaded. Unable to select one automatically.")
        }
    }
    
    /// Selects an AI model to be the primary, active model.
    func selectActive(model: EdgeClient.AI.Model, automatic: Bool) {
        selectedModel = model
        
        guard let modelId = selectedModel?.id else {
            return
        }
        
        let value = "\(automatic ? "automatically" : "user")"
        responseLabel1 = "\(modelId)"
        responseLabel2 = "(\(value) selected model)"
        questionLabel = "Question"
        menuLabel = ""
    }
    
    /// Processes incoming AI model data, shows appropriate UI prompts based on the type.
    fileprivate func processIncomingData(stream: EdgeClient.AI.Model.CompletionType) {
        switch stream {
        case .content(let content):
            if response.contains("Model Ready") || response.contains("Model Loading") {
                response = content
                return
            }
            
            response = response + content
        case .modelLoading:
            response = "Model Loading, please wait"
        case .modelReady:
            response = "Model Ready, please wait"
        case .streamDone:
            response = response + "\n\n[Done]"
        case .comment, .event, .id, .retry:
            print("other")
        @unknown default:
            print("unknown")
        }
    }
    
    /// Shows a user facing error in the UI.
    fileprivate func showError(text: String) {
        
        if text.contains("Request explicitly cancelled") {
            response = response + "\n\n[Request user cancelled]"
        }
        else {
            response = text
        }
        
        isWaiting = false
        activeStream = nil
        print("⚠️ Error:", text)
    }
}
