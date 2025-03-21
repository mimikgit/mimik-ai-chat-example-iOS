//
//  MenuView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-18.
//

import Alamofire
import EdgeCore
import SwiftUI

struct MenuView: View {

    @Binding internal var activeStream: DataStreamRequest?
    @Binding internal var activeNonStream: DataTask<Data>?
    @Binding internal var showAddModel: Bool
    @Binding internal var streamResponse: Bool
    @Binding internal var downloadedModels: [EdgeClient.AI.Model]
    @Binding internal var selectedModel: EdgeClient.AI.Model?
    @Binding internal var isWaiting: Bool
    @Binding internal var mimOEVersion: String
    
    @State internal var owner: ContentView

    var body: some View {
        VStack(spacing: 10) {
            if activeStream == nil && activeNonStream == nil {
                Menu {
                    Menu("Remove") {
                        ForEach(downloadedModels, id: \.self) { model in
                            Button("Remove \(model.id ?? "NOT_AVAILABLE")", systemImage: "trash", role: .destructive) {
                                Task {
                                    print("delete model task")
                                    _ = await owner.deleteAIModel(id: model.id ?? "N/A")
                                }
                            }.disabled(downloadedModels.isEmpty)
                        }
                        
                        Button("Remove Everything", systemImage: "trash.fill", role: .destructive) {
                            Task {
                                print("remove everything task")
                                await owner.removeEverything()
                            }
                        }
                    }
                    
                    ForEach(downloadedModels, id: \.self) { model in
                        Button("Select \(model.id ?? "")") {
                            Task {
                                print("select active task")
                                await owner.selectActive(model: model, automatic: false)
                            }
                        }
                    }
                                    
                    Button("Add AI Model", systemImage: "plus") {
                        showAddModel = true
                    }
                    
                    Toggle(streamResponse ? "Streaming is ON" : "Streaming is OFF", isOn: $streamResponse)
                        .toggleStyle(.button)
                    
                    Text("App: \(ConfigManager.versionBuild()), mim OE: \(mimOEVersion)")
                    Text("Token expires on: \(ConfigManager.tokenExpiration())")
                    
                } label: {
                    Label(manageModelsLabel(), systemImage: manageModelsIcon())
                }
                .font(manageModelsFont())
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(manageModelsColour())
            }
            else {
                Button("Cancel Request", systemImage: "xmark", role: .destructive) {
                    Task {
                        print("some cancellation task")
                        activeStream?.cancel()
                        activeNonStream?.cancel()
                    }
                }
                .font(manageModelsFont())
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    private func manageModelsIcon() -> String {
        
        if downloadedModels.isEmpty {
            return "gear.badge"
        }
        else {
            return "gear"
        }
    }
    
    private func manageModelsFont() -> Font {
        if selectedModel != nil && downloadedModels.count >= 1 {
            .title3
        }
        else {
            .title
        }
    }
    
    private func manageModelsColour() -> Color {
        
        if isWaiting {
            return .gray
        }
        
        if downloadedModels.count >= 1 {
            if selectedModel != nil {
                return .blue
            }
            else {
                return .red
            }
        }
        else {
            return .red
        }
    }
    
    private func manageModelsLabel() -> String {
        
        if downloadedModels.isEmpty {
            return "START HERE"
        }
        else {
            if let selectedModelId = selectedModel?.id {
                return selectedModelId
            }
            else {
                return "SELECT A MODEL"
            }
        }
    }
}
