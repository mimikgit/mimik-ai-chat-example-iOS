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

    @EnvironmentObject var appState: StateService
    @EnvironmentObject var engineService: EngineService
    @EnvironmentObject var modelService: ModelService
    
    @Binding internal var showAddModelTablet: Bool
    @Binding internal var showAddModelPhone: Bool

    var body: some View {
        VStack(spacing: 10) {
            Menu {
                Menu("Remove") {
                    ForEach(appState.downloadedModels, id: \.self) { model in
                        
                        Button("Remove \(model.kind == .vlm ? "(vlm)" : "(llm)") \(model.id ?? "")", systemImage: "trash", role: .destructive) {
                            Task {
                                try await modelService.deleteAIModel(id: model.id ?? "N/A")
                                appState.generalMessage = "<\(model.id ?? "")> model removed."
                                try await Task.sleep(nanoseconds: 2_000_000_000)
                                appState.resetGeneralMessage()
                            }
                        }.disabled(appState.downloadedModels.isEmpty)
                    }
                    
                    Button("Remove Everything", systemImage: "trash.fill", role: .destructive) {
                        Task {
                            appState.generalMessage = "Please Wait..."
                            try await engineService.removeEverything()
                            appState.stateReset()
                        }
                    }
                }
                
                ForEach(appState.downloadedModels, id: \.self) { model in
                    Button("Select \(model.kind == .vlm ? "(vlm)" : "(llm)") \(model.id ?? "")") {
                        Task {
                            appState.generalMessage = "Please Wait..."
                            await modelService.selectActive(model: model, automatic: false)
                            appState.generalMessage = "Active model changed to <\(model.id ?? "")>"
                            try await Task.sleep(nanoseconds: 5_000_000_000)
                            appState.resetGeneralMessage()
                        }
                    }
                }
                                
                Button("Add AI Model", systemImage: "plus") {
                    if DeviceType.isTablet {
                        showAddModelTablet = true
                    }
                    else {
                        showAddModelPhone = true
                    }
                }
                
                Text("App: \(ConfigService.versionBuild()), mim OE: \(engineService.mimOEVersion)")
                Text("Token expires on: \(ConfigService.tokenExpiration())")
                
            } label: {
                VStack {
                    if appState.selectedModel != nil {
                        MetallicText(text: appState.selectedModel?.kind == .vlm ? "vlm" : "llm", fontSize: DeviceType.isTablet ? 20 : 14, color: .gold, icon: DeviceType.isTablet ? nil: "gear.badge", iconPosition: .after)
                    }
                    MetallicText(text: manageModelsLabel(), fontSize: DeviceType.isTablet ? 32 : 20, color: .gold, icon: DeviceType.isTablet ? "gear.badge" : nil, iconPosition: .after)
                }
            }
            .font(manageModelsFont())
            .foregroundColor(manageModelsColour())
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
    
    private func manageModelsColour() -> Color {
        
        if appState.activeStream != nil {
            return .gray
        }
        
        if appState.downloadedModels.count >= 1 {
            if appState.selectedModel != nil {
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
        
        if appState.downloadedModels.isEmpty {
            return "START HERE"
        }
        else {
            if appState.selectedModel != nil{
                return "READY"
            }
            else {
                return "SELECT"
            }
        }
    }
}
