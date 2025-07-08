//
//  ContentView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-17.
//

import SwiftUI
import PhotosUI
import EdgeCore
import Alamofire
import SwiftyJSON

struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var engineService: EngineService
    @EnvironmentObject private var modelService: ModelService
    @EnvironmentObject var authState: AuthState
    
    @FocusState private var isFocused: Bool
    @State private var showLoading: Bool = false
    @State private var loadingMessage: String = ""
    
    var body: some View {
        
        LoadingView(isShowing: $showLoading, text: loadingMessage) {
            
            ZStack {
                Image("Full Background")
                    .resizable()
                    .edgesIgnoringSafeArea([.bottom, .top])
                
                VStack() {
                    
                    TopTitleStackView()
                        .customBackground(backgroundColor: Color(UIColor.systemFill), cornerRadius: 15.0)
                        .padding()
                        .padding(.top)
                        .frame(maxWidth: ScreenSize.screenWidth, maxHeight: DeviceType.isTablet ? 200 : 180)
                        .zIndex(1)
                    
                    if !appState.downloadedModels.isEmpty {
                        
                        if appState.selectedModel == nil {
                            HStack {
                                Spacer()
                                MetallicText(text: "Select a model", fontSize: 32, color: .silver, icon: "arrow.up", iconPosition: .before)
                                Spacer()
                                MetallicText(text: "Learn more", fontSize: 32, color: .silver, icon: "arrow.up", iconPosition: .after)
                                Spacer()
                            }
                        }
                        
                        ChatMessagesView()
                            .frame(maxWidth: ScreenSize.screenWidth, maxHeight: ScreenSize.screenHeight * 0.7)
                            .customBackground(backgroundColor: !appState.downloadedModels.isEmpty ? Color(UIColor.systemFill) : .clear, cornerRadius: 15.0)
                            .padding()
                        
                        BottomChatView()
                            .customBackground(backgroundColor: !appState.downloadedModels.isEmpty ? Color(UIColor.systemFill) : .clear, cornerRadius: 15.0)
                            .padding()
                    }
                }
            }
            .keyboardAdaptive()
            .edgesIgnoringSafeArea(.all)
            .task {
                Task {
                    await startupTask()
                }
            }
            .onChange(of: appState.selectedModel) { oldModel, newNewModel in
                Task {
                    modelService.configuredServices.removeAll()
                    try await Task.sleep(nanoseconds: 250_000_000)
                    if let selectedModelId = appState.selectedModel?.id, let milmApiKey = ConfigService.fetchConfig(for: .milmApiKey), let mimOEPort = engineService.mimOEPort() {
                        authState.saveToken(token: milmApiKey, serviceKind: .mimikAI, tokenType: .developerToken)
                        modelService.configuredServices.append(EdgeClient.AI.ServiceConfiguration(kind: .mimikAI, modelId: selectedModelId, apiKey: milmApiKey, mimOEPort: mimOEPort, mimOEClientId: engineService.mimOEClientId))
                        modelService.configuredServices.append(EdgeClient.AI.ServiceConfiguration(kind: .gemini, modelId: "gemini-2.0-flash", apiKey: nil, mimOEPort: nil, mimOEClientId: nil))
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    // Application went to the background, cancelling active stream
                    appState.activeStream?.cancel()
                }
            }
            .sheet(item: $appState.tokenInputService) { service in
                TokenInputStackView(tokenInputService: service)
                    .environmentObject(appState)
                    .environmentObject(authState)
                    .environmentObject(modelService)
            }
        }
    }
    
    func startupTask() async {
        do {
            try await engineService.startupProcedure()
            await modelService.processAvailableAIModels()
        }
        catch {
            print("Error during startup procedure: \(error)")
            appState.generalMessage = error.localizedDescription
        }
    }
}
