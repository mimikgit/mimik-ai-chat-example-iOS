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
    
    @State var owner: ContentView
    
    @Binding var userInput: String
    @Binding var question: String
    @Binding var storedResponse: String
    @Binding var bottomMessage: String
    @Binding var selectedModel: EdgeClient.AI.Model?
    @Binding var selectedImage: UIImage?
    @Binding var streamResponse: Bool
    @Binding var lastUsage: EdgeClient.AI.Model.Usage?
    @Binding var showImagePicker: Bool
    @Binding var isFileImporterPresented: Bool
    @Binding var isWaiting: Bool
    @Binding var activeStream: DataStreamRequest?
    @Binding var activeNonStream: DataTask<Data>?
    @Binding var downloadedModels: [EdgeClient.AI.Model]
    
    var body: some View {
        HStack {
            TextField("", text: $userInput, prompt: Text(userInputPrompt()).foregroundStyle(userInputStyle()))
                .onSubmit {
                    handleUserInputSubmit()
                }
            
            if selectedModel?.kind == .vlm {
                PhotoPickerView(
                    selectedImage: $selectedImage,
                    showImagePicker: $showImagePicker,
                    isFileImporterPresented: $isFileImporterPresented,
                    isWaiting: $isWaiting
                )
            }
        }
    }
    
    private func handleUserInputSubmit() {
        // Store the question and reset user input
        question = userInput
        userInput = ""
        storedResponse = ""
        
        Task {
            bottomMessage = ""
            
            if streamResponse {
                // Handle streaming response logic
                if selectedModel?.kind == .vlm, let image = selectedImage {
                    guard case .success(_) = await owner.visualAIStream(question: question, image: image) else {
                        return
                    }
                } else {
                    guard case .success(_) = await owner.chatAIStream(question: question) else {
                        return
                    }
                }
            } else {
                guard case .success(_) = await owner.chatAIDirect(question: question) else {
                    return
                }
            }

            if let lastUsage = lastUsage {
                var message = "Tokens: \(lastUsage.totalTokens ?? 0) (prompt: \(lastUsage.promptTokens ?? 0) + completion: \(lastUsage.completionTokens ?? 0)"
                
                if lastUsage.totalTokens ?? 0 == 2048 {
                    message += " , **limit reached**)"
                } else {
                    message += ")"
                }
                
                bottomMessage = "**Performance: \(lastUsage.tokenPerSecond?.rounded(.awayFromZero) ?? 0) tokens per second**. \n\(message)"
            }
        }
    }
    
    private func userInputPrompt() -> String {
        
        if activeStream != nil  {
            return "Streaming response"
        }
        
        if activeNonStream != nil {
            return "Waiting for non-streamed response."
        }
        
        if isWaiting {
            return "Model warmup. Please wait."
        }
        
        let message = selectedModel?.kind == .llm ? "Enter your question for the selected llm" : "Attach an image and enter your question for the selected vlm"
        return downloadedModels.count >= 1 ? message : ""
    }
    
    private func userInputColour() -> Color {
        
        if isWaiting {
            return .gray
        }
        
        return downloadedModels.count >= 1 ? .red : .clear
    }
    
    private func userInputStyle() -> any ShapeStyle {
        
        if isWaiting {
            return .gray
        }
        
        return downloadedModels.count >= 1 ? .red : .gray
    }
}
