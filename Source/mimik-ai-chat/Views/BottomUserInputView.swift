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
    
    @EnvironmentObject private var appState: StateService
    @EnvironmentObject private var modelService: ModelService
    @FocusState private var isFocused: Bool
    
    @State private var showInputOptions: Bool = false
    
    @Binding var userInput: String
    @Binding var question: String
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
        }
    }
    
    private var infoBlockView: some View {
        HStack {
            if appState.activeStream == nil {
                                
                if appState.selectedModel?.kind == .vlm, appState.performanceMessage.isEmpty, !showInputOptions {
                    MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .ruby, icon: showInputOptions ? "xmark" : "plus", iconPosition: .after) {
                        showInputOptions.toggle()
                    }
                }
                
                MetallicText(text: appState.infoMessage, fontSize: DeviceType.isTablet ? 25 : 16, color: .gold, lineLimit: LineLimit(lineLimit: DeviceType.isTablet ? 1 : 3, reservesSpace: false))
                
                if !appState.performanceMessage.isEmpty {
                    MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .silver, icon: "trash", iconPosition: .after) {
                        appState.resetContextState()
                    }

                    MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .silver, icon: "document.on.document", iconPosition: .after) {
                        pasteboardCopy(from: appState.postedMessages)
                    }
                }
            }
            else {
                MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .ruby, icon: "xmark", iconPosition: .after) { appState.resetContextState() }
                MetallicText(text: appState.generalMessage, fontSize: DeviceType.isTablet ? 25 : 16, color: .gold, lineLimit: LineLimit(lineLimit: DeviceType.isTablet ? 1 : 3, reservesSpace: false))
            }
        }
    }
    
    private var userInputPrompt: String {
        return appState.activeStream != nil ? "Streaming response" : ">"
    }
    
    private func pasteboardCopy(from messages: [EdgeClient.AI.Model.Message]) {
        var result: [String] = []

        for message in messages {
            if let content = message.content {
                if message.isUserType {
                    result.append("Prompt: \(content)")
                } else if message.isAiType {
                    result.append("Response: \(content)")
                }
            }
        }
        UIPasteboard.general.string = result.joined(separator: "\n")
    }
    
    private func handleUserInputSubmit() async throws {
        question = userInput
        userInput = ""
        
        appState.generalMessage = ""
        showInputOptions = false
        
        do {
            if appState.selectedModel?.kind == .vlm {
                
                guard let image = appState.selectedImage else {
                    appState.generalMessage = "Attach an image to continue"
                    return
                }
                
                try await modelService.visionAIStream(question: question, image: image)
            } else {
                try await modelService.chatAIStream(question: question)
            }
            
            if let lastUsage = appState.lastTokenUsage {
                var moreMsg = "Tokens: \(lastUsage.totalTokens ?? 0) (prompt: \(lastUsage.promptTokens ?? 0) + completion: \(lastUsage.completionTokens ?? 0)"
                
                if lastUsage.totalTokens ?? 0 == 2048 {
                    moreMsg += " , **limit reached**)"
                } else {
                    moreMsg += ")"
                }
                
                appState.performanceMessage = "Performance: \(lastUsage.tokenPerSecond?.rounded(.awayFromZero) ?? 0) tokens per second. \(moreMsg)"
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
