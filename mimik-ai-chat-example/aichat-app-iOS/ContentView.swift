//
//  ContentView.swift
//

import SwiftUI
import EdgeCore
import Alamofire
import SwiftyJSON

struct ContentView: View {
    
    internal let kAIUseCaseDeployment = "kAIUseCaseDeployment"
    
    // AI
    @State internal var mimOEAccessToken: String = ""
    @State internal var activeStream: DataStreamRequest?
    @State internal var selectedModel: EdgeClient.AI.Model?
    @State internal var downloadedModels: [EdgeClient.AI.Model] = []
    
    // State
    @State internal var isWaiting: Bool = false
    @State internal var startupDone: Bool = false
    @State internal var showAddModel: Bool = false
    @FocusState private var isFocused: Bool
    @Environment(\.scenePhase) var scenePhase
    
    // UI
    @State internal var question: String = ""
    @State internal var questionLabel: String = ""
    @State internal var userInput: String = ""
    @State internal var response: String = ""
    @State internal var responseLabel: String = ""
    @State internal var menuLabel: String = ""
    
    // mimik Client Library
    let edgeClient: EdgeClient = {
        EdgeClient.setLoggingLevel(module: .edgeCore, level: .debug, privacy: .publicAccess)
        EdgeClient.setLoggingLevel(module: .edgeEngine, level: .debug, privacy: .publicAccess)
        return EdgeClient()
    }()
    
    // This is where we store the AI use case deployment information
    internal var useCaseDeployment: EdgeClient.UseCase.Deployment? {
        get {
            if let data = UserDefaults.standard.object(forKey: kAIUseCaseDeployment) as? Data,
               let deployment = try? JSONDecoder().decode(EdgeClient.UseCase.Deployment.self, from: data) {
                return deployment
            }
            
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("**mimik AI Chat**").font(.title)
                .padding()
            
            Text(questionLabel).font(.title2.weight(downloadedModels.count >= 1 ? .light : .ultraLight)).frame(maxWidth: .infinity, minHeight: 40).border(downloadedModels.count >= 1 ? Color.gray : Color.clear)

            Text(question).font(.title2.weight(.bold)).frame(maxWidth: .infinity, alignment: .leading)
            
            Text(responseLabel).font(.title2.weight(downloadedModels.count >= 1 ? .light : .ultraLight)).frame(maxWidth: .infinity, minHeight: 40).border(downloadedModels.count >= 1 ? Color.gray : Color.clear)
            
            ScrollView {
                ScrollViewReader { value in
                    Text(response).font(.title3.weight(.regular)).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .defaultScrollAnchor(.bottom)
            
            VStack(spacing: 20) {
                                            
                if startupDone {
                    TextField("", text: $userInput, prompt: Text(userInputPrompt()).foregroundStyle(userInputStyle())).onSubmit {
                        question = userInput
                        userInput = ""
                        response = ""
                        Task {
                            await askAI(question: question)
                        }
                    }
                    .disabled(isWaiting)
                    .textFieldModifier(borderColor: userInputColour(), lineWidth: downloadedModels.count >= 1 ? 3 : 1)
                    
                    VStack(spacing: 5) {
                        menuView()
                        Text(menuLabel).font(.title3.weight(.regular))
                    }
                }
            }

        }
        .sheet(isPresented: $showAddModel) {
            SheetView(modelId: selectedModel?.id ?? "", modelObject: selectedModel?.object?.rawValue ?? "", modelUrl: selectedModel?.url ?? "", modelOwnedBy: selectedModel?.ownedBy ?? "", modelExpectedDownloadSize: 0, owner: self)
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
        }
        .padding()
        .task {
            // Running the startup procedure when the view loads the first time
            Task {
                startupDone = false
                _ = await startupProcedure()
                startupDone = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Application went to the background, cancelling active stream
                activeStream?.cancel()
            }
        }
    }
    
    func menuView() -> some View {
        VStack(spacing: 10) {
            Menu {
                Button("Remove All Models", systemImage: "trash", role: .destructive) {
                    Task {
                        _ = await resetMimOE()
                        _ = await startupProcedure()
                    }
                }.disabled(selectedModel == nil)
                
                ForEach(downloadedModels, id: \.self) { model in
                    Button(model.id ?? "") {
                        selectActive(model: model, automatic: false)
                    }
                }
                
                Button("Add AI Model", systemImage: "plus") {
                    showAddModel = true
                }
                
            } label: {
                Label(downloadModelLabel(), systemImage: downloadModelIcon())
            }.font(downloadedModels.count >= 1 ? .title3 : .title).frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(downloadedModels.count >= 1 ? .blue : .red)

            if activeStream != nil {
                Button("Cancel Request", systemImage: "xmark", role: .destructive) {
                    activeStream?.cancel()
                }.font(.system(size: 30))
            }
        }
    }
}
