//
//  BottomUserInputView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-19.
//

import EdgeCore
import SwiftUI
import Alamofire

struct BottomChatInputView: View {
    
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var modelService: ModelService
    @FocusState private var isFocused: Bool
    
    @State private var showInputOptions: Bool = false    
    
    @Binding var userInput: String
    @Binding var prompt: String
    @Binding var showImagePicker: Bool
    @Binding var showFileImporter: Bool
    
    var body: some View {
        VStack {
            
            VStack {
                if showInputOptions {
                    InputOptionsView(
                        showImagePicker: $showImagePicker,
                        showInputOptions: $showInputOptions,
                        showFileImporter: $showFileImporter,
                        fontSize: DeviceType.isTablet ? 25 : 16
                    )
                    .customBackground(backgroundColor: Color(UIColor.systemFill), cornerRadius: 15)
                }
                
                infoBlockView
            }
            
            HStack {
                TextField("", text: $userInput, prompt: Text(userInputPrompt).foregroundStyle(Color.roseGold).font(.system(size: DeviceType.isTablet ? 25 : 16)))
                    .onSubmit {
                        Task {
                            if !userInput.isEmpty {
                                try? await handleUserInputSubmit()
                            }
                        }
                    }
                    .focused($isFocused)
                    .foregroundStyle(.white)
                    .disabled(appState.activeStream != nil)
            }
            .padding()
            
            listModelsView
        }
        .task {
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                modelService.reAuthorizeServices()
            }
        }
    }
    
    private var infoBlockView: some View {
        HStack {
            if appState.activeStream == nil {
                 
                VStack {
                    HStack {
                        if appState.selectedModel?.kind == .vlm, !showInputOptions {
                            MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .ruby, icon: showInputOptions ? "xmark" : "plus", iconPosition: .after) {
                                showInputOptions.toggle()
                            }
                        }
                        
                        MetallicText(text: modelService.infoMessage, fontSize: DeviceType.isTablet ? 25 : 16, color: .gold, lineLimit: LineLimit(lineLimit: DeviceType.isTablet ? 2 : 3, reservesSpace: false))

                        Spacer()
                        
                        AdaptiveStack(phone:  .vertical, tablet: .horizontal, alignment: .center, spacing: 5) {
                            MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .silver, icon: "trash", iconPosition: .after) {
                                appState.resetContextState()
                            }
                            
                            MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .silver, icon: "document.on.document", iconPosition: .after) {
                                UIPasteboard.general.string = appState.messagesForCopying()
                            }
                        }
                    }
                }
            }
            else {
                MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .ruby, icon: "xmark", iconPosition: .after) { appState.resetContextState() }
                MetallicText(text: appState.generalMessage, fontSize: DeviceType.isTablet ? 25 : 16, color: .gold, lineLimit: LineLimit(lineLimit: DeviceType.isTablet ? 1 : 3, reservesSpace: false))
            }
        }
    }
  
    private var listModelsView: some View {
        HStack(spacing: 16) {
            
            MetallicText(text: "Models:", fontSize: DeviceType.isTablet ? 21 : 16, color: .gold, lineLimit: LineLimit(lineLimit: DeviceType.isTablet ? 2 : 3, reservesSpace: false))

            let authorizedServices = modelService.configuredServices(sortedFirstBy: .gemini).filter { service in
                authState.accessToken(serviceKind: service.kind, tokenType: .developerToken) != nil
            }
            
            ForEach(authorizedServices, id: \.modelId) { service in
                MetallicText(
                    text: service.kind.rawValue,
                    fontSize: DeviceType.isTablet ? 21 : 16,
                    color: .silver,
                    icon: "list.bullet.rectangle",
                    iconPosition: .after
                ) {
                    Task {
                        try await modelService.availableModels(configuration: service)
                    }
                }
            }
            
            Spacer()
        }
    }

    private var userInputPrompt: String {
        return appState.activeStream != nil ? "Streaming response" : ">"
    }
    
    private func handleUserInputSubmit() async throws {
        prompt = userInput
        userInput = ""
        
        appState.generalMessage = ""
        showInputOptions = false
        
        do {
            if appState.selectedModel?.kind == .vlm {
                
                guard let image = appState.selectedImage else {
                    appState.generalMessage = "Attach an image to continue"
                    return
                }
                            
                if let promptService = modelService.configuredServices(sortedFirstBy: .mimikAI).first(where: { $0.modelId == appState.selectedModel?.id }) {
                    try await modelService.assistantVisionPrompt(configuration: promptService, prompt: prompt, image: image)
                }
                
            } else {
                if let promptService = modelService.configuredServices(sortedFirstBy: .mimikAI).first(where: { $0.modelId == appState.selectedModel?.id }) {
                    try await modelService.assistantPrompt(configuration: promptService, prompt: prompt, isValidation: false)
                             
                    if let validateService = modelService.primaryValidateService, authState.accessToken(serviceKind: validateService.kind, tokenType: .developerToken) != nil {                                                
                        try await modelService.assistantPrompt(configuration: validateService, prompt: "", isValidation: true)
                    }
                }
            }
        }
        catch let error as NSError {
            print("error: \(error.localizedDescription)")
            appState.generalMessage = error.localizedDescription
            throw error
        }
    }
    
    private func userInputStyle() -> some ShapeStyle {
        if appState.activeStream != nil {
            return .gray
        }
        
        return appState.downloadedModels.isEmpty ? .clear : .gray
    }
}
