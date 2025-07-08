//
//  MenuViewOnDevice.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-18.
//

import Alamofire
import EdgeCore
import SwiftUI

struct MenuViewOnDevice: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var engineService: EngineService
    @EnvironmentObject var modelService: ModelService
    
    @Binding internal var showAddModelTablet: Bool
    @Binding internal var showAddModelPhone: Bool

    var body: some View {
        VStack(spacing: 10) {
            Menu {
                Button("Add New Model", systemImage: "plus") {
                    if DeviceType.isTablet {
                        showAddModelTablet = true
                    }
                    else {
                        showAddModelPhone = true
                    }
                }
                
                ForEach(appState.downloadedModels, id: \.self) { model in
                    Button("Select \(model.kind == .vlm ? "<vision>" : "") \(model.id ?? "")") {
                        Task {
                            appState.generalMessage = "Please Wait..."
                            await modelService.selectActive(model: model, automatic: false)
                            appState.generalMessage = "Active model changed to <\(model.id ?? "")>"
                            try await Task.sleep(nanoseconds: 5_000_000_000)
                            modelService.resetGeneralMessage()
                        }
                    }
                }
                
                Menu("Remove") {
                    ForEach(appState.downloadedModels, id: \.self) { model in
                        
                        Button("Remove \(model.kind == .vlm ? "<vision>" : "") \(model.id ?? "")", systemImage: "trash", role: .destructive) {
                            Task {
                                try await modelService.deleteAIModel(id: model.id ?? "N/A")
                                appState.generalMessage = "<\(model.id ?? "")> model removed."
                                try await Task.sleep(nanoseconds: 2_000_000_000)
                                modelService.resetGeneralMessage()
                            }
                        }.disabled(appState.downloadedModels.isEmpty)
                    }
                    
                    Button("Remove Everything", systemImage: "trash.fill", role: .destructive) {
                        Task {
                            appState.generalMessage = "Please Wait..."
                            try await engineService.removeEverything()
                            
                            appState.stateReset()
                            authState.deleteAllTokens()
                        }
                    }
                }
                
                Text("App: \(ConfigService.versionBuild()), mim OE: \(engineService.mimOEVersion)")
                Text("Token expires on: \(ConfigService.tokenExpiration())")
                
            } label: {
                VStack {
                    if appState.selectedModel != nil {
                        MetallicText(text: "On Device", fontSize: DeviceType.isTablet ? 28 : 12, color: .silver)
                        MetallicText(text: appState.selectedModel?.kind == .vlm ? "vision Prompt" : "Prompt", fontSize: DeviceType.isTablet ? 28 : 12, color: .amethyst)
                    }
                    MetallicText(text: infoLabel(), fontSize: DeviceType.isTablet ? 32 : 12, color: infoLabelColour(), icon: "gear.badge", iconPosition: .after)
                }
            }
            .font(manageModelsFont())
        }
        .popover(isPresented: $showAddModelTablet) {
            AddModelView()
                .background(
                    Image("Black-Background").opacity(0.8)
                )
                .ignoresSafeArea()
                .environmentObject(appState)
                .environmentObject(engineService)
                .environmentObject(modelService)
        }
        .sheet(isPresented: $showAddModelPhone) {
            AddModelView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .background(
                    Image("Black-Background").opacity(0.9)
                )
                .ignoresSafeArea()
                .environmentObject(appState)
                .environmentObject(engineService)
                .environmentObject(modelService)
        }
    }
    
    private func manageModelsFont() -> Font {
        if appState.selectedModel != nil && appState.downloadedModels.count >= 1 {
            .title3
        }
        else {
            .title
        }
    }
    
    private func infoLabelColour() -> MetallicText.MetallicColor {
        if isPromptReady {
            return .gold
        }
        else if infoLabel().contains("START HERE") {
            return .ruby
        }
        else {
            return .obsidian
        }
    }
    
    private var isPromptReady: Bool {
        return !appState.downloadedModels.isEmpty
    }
    
    private func infoLabel() -> String {
        return isPromptReady ? "READY" : "START HERE"
    }
}
