//
//  BottomStackView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-19.
//

import Alamofire
import EdgeCore
import SwiftUI

struct BottomChatView: View {
    
    @State var owner: ContentView
    @State private var userInput: String = ""
    @State private var question: String = ""
    @State private var showImagePicker: Bool = false
    @State private var showAddModel: Bool = false
    @State private var streamResponse: Bool = true
    @State private var isFileImporterPresented: Bool = false
    
    @Binding var storedResponse: String
    @Binding var startupDone: Bool
    @Binding var selectedModel: EdgeClient.AI.Model?
    @Binding var isWaiting: Bool
    @Binding var downloadedModels: [EdgeClient.AI.Model]
    @Binding var storedLiveContent: [EdgeClient.AI.Model.Message]
    @Binding var selectedImage: UIImage?
    @Binding var selectedFileURL: URL?
    @Binding var activeStream: DataStreamRequest?
    @Binding var activeNonStream: DataTask<Data>?
    
    @Binding var mimOEVersion: String
    @Binding var bottomMessage: String
    @Binding var lastUsage: EdgeClient.AI.Model.Usage?
    
    var body: some View {
        VStack(spacing: 20) {
            if startupDone {
                if selectedModel != nil {
                    BottomChatInputView(owner: owner, userInput: $userInput, question: $question, storedResponse: $storedResponse, bottomMessage: $bottomMessage, selectedModel: $selectedModel, selectedImage: $selectedImage, streamResponse: $streamResponse, lastUsage: $lastUsage, showImagePicker: $showImagePicker, isFileImporterPresented: $isFileImporterPresented, isWaiting: $isWaiting, activeStream: $activeStream, activeNonStream: $activeNonStream, downloadedModels: $downloadedModels)
                        .disabled(isWaiting)
                        .textFieldModifier(borderColor: userInputColour(), lineWidth: downloadedModels.count >= 1 ? 2 : 1)
                        .fileImporter(
                            isPresented: $isFileImporterPresented,
                            allowedContentTypes: FileTypes.allowedContentTypes(for: [.image]),
                            allowsMultipleSelection: false
                        ) { result in
                            handleFileSelection(result: result)
                        }
                }

                VStack(spacing: 5) {
                    if selectedModel != nil && (storedLiveContent.count > 0 || selectedImage != nil) {
                        Button("Clear Context", systemImage: "trash", role: .destructive) {
                            owner.clearContext()
                        }
                        .font(manageModelsFont())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .disabled(isWaiting)
                        
                        Button("Copy Context", systemImage: "document.on.document", role: .none) {
                            UIPasteboard.general.string = owner.textToFlow()
                        }
                        .font(manageModelsFont())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .disabled(isWaiting)
                    }
                }

                HStack {
                    MenuView(
                        activeStream: $activeStream,
                        activeNonStream: $activeNonStream,
                        showAddModel: $showAddModel,
                        streamResponse: $streamResponse,
                        downloadedModels: $downloadedModels,
                        selectedModel: $selectedModel,
                        isWaiting: $isWaiting,
                        mimOEVersion: $mimOEVersion,
                        owner: owner
                    )
                }
                .frame(maxWidth: .infinity, minHeight: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(manageModelsBorderColour(), lineWidth: 2)
                )
            }

            if !bottomMessage.isEmpty {
                Text(markdownBottomMessage ?? "")
            }
        }
        .sheet(isPresented: $showImagePicker) {
            PhotoPicker(selectedImage: $selectedImage, showImagePicker: $showImagePicker)
        }
        .sheet(isPresented: $showAddModel) {
            let model = AddModelView.Model(id: selectedModel?.id ?? "", object: selectedModel?.object?.rawValue ?? "", url: selectedModel?.url ?? "", mmprojUrl: selectedModel?.mmprojUrl ?? "", chatHint: selectedModel?.modelChatHint ?? "", ownedBy: selectedModel?.ownedBy ?? "", kind: selectedModel?.kind?.rawValue ?? ".llm", excludeFromBackup: selectedModel?.excludeFromBackup ?? true, expectedDownloadSize: 0)
            AddModelView(model: model, owner: owner)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var markdownBottomMessage: AttributedString? {
        return try? AttributedString(markdown: bottomMessage, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }
    
    private func handleFileSelection(result: (Result<[URL], any Error>)) -> Void {
        switch result {
        case .success(let urls):
            print("File selection: \(urls)")
            selectedFileURL = urls.first
            
            if let path = urls.first?.path(), let image = UIImage.init(contentsOfFile: path) {
                selectedImage = image
            }
            
        case .failure(let error):
            print("File selection failed: \(error.localizedDescription)")
        }
    }
    
    private func manageModelsBorderColour() -> Color {
        
        if isWaiting {
            return .gray
        }
        
        if downloadedModels.isEmpty || selectedModel == nil {
            return .clear
        }
        
        if isWaiting || activeStream != nil || activeNonStream != nil {
            return .red
        }
        
        return .blue
    }
    
    private func manageModelsFont() -> Font {
        if selectedModel != nil && downloadedModels.count >= 1 {
            .title3
        }
        else {
            .title
        }
    }
    
    private func userInputColour() -> Color {
        
        if isWaiting {
            return .gray
        }
        
        return downloadedModels.count >= 1 ? .red : .clear
    }
}
