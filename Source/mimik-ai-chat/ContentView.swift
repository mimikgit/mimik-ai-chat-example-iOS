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
    @State internal var justDownloadedModelId: String?
    @State internal var downloadedModels: [EdgeClient.AI.Model] = []
    
    // State
    @State internal var isWaiting: Bool = false
    @State internal var startupDone: Bool = false
    @State internal var showAddModel: Bool = false
    @State internal var showSwitchModel: Bool = false
    @FocusState private var isFocused: Bool
    @Environment(\.scenePhase) var scenePhase
    
    // UI
    @State internal var question: String = ""
    @State internal var questionLabel: String = ""
    @State internal var userInput: String = ""
    @State internal var response: String = ""
    @State internal var responseLabel1: String = ""
    @State internal var responseLabel2: String = ""
    @State internal var menuLabel: String = ""
    
    // mimik Client Library
    let edgeClient: EdgeClient = {
        EdgeClient.setLoggingLevel(module: .edgeCore, level: .debug, privacy: .publicAccess)
        EdgeClient.setLoggingLevel(module: .edgeEngine, level: .debug, privacy: .publicAccess)
        return EdgeClient()
    }()
    
    // This is where we store the AI use case deployment information
    internal var deployedUseCase: EdgeClient.UseCase? {
        get {
            if let data = UserDefaults.standard.object(forKey: kAIUseCaseDeployment) as? Data,
               let deployment = try? JSONDecoder().decode(EdgeClient.UseCase.self, from: data) {
                return deployment
            }
            
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("**mimik ai chat**").font(.title)
                .padding()
            
            if selectedModel != nil {
                Text(questionLabel).font(.title2.weight(downloadedModels.count >= 1 ? .light : .ultraLight)).frame(maxWidth: .infinity, minHeight: 40).border(downloadedModels.count >= 1 ? Color.gray : Color.clear)

                Text(question).font(.title2.weight(.bold)).frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 5) {
                    Text(responseLabel1).font(.title2.weight(downloadedModels.count >= 1 ? .bold : .ultraLight))
                    Text(responseLabel2).font(.title2.weight(downloadedModels.count >= 1 ? .light : .ultraLight))
                }.frame(maxWidth: .infinity, minHeight: 40).border(downloadedModels.count >= 1 ? Color.gray : Color.clear)
                
                ScrollView {
                    ScrollViewReader { value in
                        Text(response).font(.title3.weight(.regular)).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .defaultScrollAnchor(.bottom)
            }
            
            VStack(spacing: 20) {
                                            
                if startupDone {
                    
                    if selectedModel != nil {
                        TextField("", text: $userInput, prompt: Text(userInputPrompt()).foregroundStyle(userInputStyle())).onSubmit {
                            question = userInput
                            userInput = ""
                            response = ""
                            Task {
                                menuLabel = ""                                
                                let clock = ContinuousClock()
                                
                                let elapsed = await clock.measure {
                                    guard case .success(_) = await askAI(question: question) else {
                                        return
                                    }
                                }
                                
                                let format = elapsed.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
                                print("⏱️⏱️⏱️ Response stream completion time (min:sec): \(format)")
                                menuLabel = "Response stream completion time (min:sec):\n\(format)"
                            }
                        }
                        .disabled(isWaiting)
                        .textFieldModifier(borderColor: userInputColour(), lineWidth: downloadedModels.count >= 1 ? 3 : 1)
                    }
                    
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
        .alert("New Model Selected", isPresented: $showSwitchModel) {
            Button("OK") {
                print("ok action")
                showSwitchModel = false
            }
        } message: {
            Text("Please double check the automatic model selection, to make sure it's what you want")
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
                
                Menu("Remove") {
                    ForEach(downloadedModels, id: \.self) { model in
                        Button("Remove \(model.id ?? "NOT_AVAIALABLE")", systemImage: "trash", role: .destructive) {
                            Task {
                                _ = await deleteAIModel(id: model.id ?? "NOT_AVAIALABLE")
                            }
                        }.disabled(downloadedModels.isEmpty)
                    }
                    
                    Button("Remove Everything", systemImage: "trash.fill", role: .destructive) {
                        Task {
                            guard case .success = await resetMimOE() else {
                                print("Failed to reset mim OE")
                                return                            }
                            
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            
                            guard case .success = await startupProcedure() else {
                                print("failed the mim OE start up procedure")
                                return
                            }
                        }
                    }
                }
                
                ForEach(downloadedModels, id: \.self) { model in
                    Button("Select \(model.id ?? "")") {
                        selectActive(model: model, automatic: false)
                    }
                }
                                
                Button("Add AI Model", systemImage: "plus") {
                    showAddModel = true
                }
                
            } label: {
                Label(downloadModelLabel(), systemImage: downloadModelIcon())
            }.font(downloadModelFont()).frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(downloadModelColour())

            if activeStream != nil {
                Button("Cancel Request", systemImage: "xmark", role: .destructive) {
                    activeStream?.cancel()
                }.font(.system(size: 30))
            }
        }
    }
}
