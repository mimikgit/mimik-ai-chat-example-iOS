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
    @EnvironmentObject private var appState: StateService
    @EnvironmentObject private var engineService: EngineService
    @EnvironmentObject private var modelService: ModelService
    
    @FocusState private var isFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
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
                        .padding(.top)
                        .frame(maxWidth: ScreenSize.screenWidth, maxHeight: 150)
                    
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
            .keyboardHeight($keyboardHeight)
            .animation(.easeInOut(duration: 1), value: 0)
            .offset(y: -keyboardHeight)
            .edgesIgnoringSafeArea(.all)
            .task {
                Task {
                    await startupTask()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    // Application went to the background, cancelling active stream
                    appState.activeStream?.cancel()
                }
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
