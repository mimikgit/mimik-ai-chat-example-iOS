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
    @State internal var mimOEVersion: String = ""
    @State internal var activeStream: DataStreamRequest?
    @State internal var activeNonStream: DataTask<Data>?
    @State internal var selectedModel: EdgeClient.AI.Model?
    @State internal var justDownloadedModelId: String?
    @State internal var downloadedModels: [EdgeClient.AI.Model] = []
    @State internal var storedLiveContent: [EdgeClient.AI.Model.Message] = []
    @State internal var storedCombinedContext: [EdgeClient.AI.Model.Message] = []
    
    // State
    @State internal var isWaiting: Bool = false
    @State internal var startupDone: Bool = false
    @State internal var showAddModel: Bool = false
    @State internal var showSwitchModel: Bool = false
    @FocusState private var isFocused: Bool
    @Environment(\.scenePhase) var scenePhase
    @State internal var streamResponse = true
    
    // UI
    @State internal var question: String = ""
    @State internal var userInput: String = ""
    @State internal var storedResponse: String = ""
    @State internal var newResponse: String = ""
    @State internal var selectedModelId: String = ""
    @State internal var bottomMessage: String = ""
    
    // mimik Client Library
    let edgeClient: EdgeClient = {
        EdgeClient.setLoggingLevel(module: .edgeCore, level: .debug, privacy: .publicAccess)
        EdgeClient.setLoggingLevel(module: .edgeEngine, level: .debug, privacy: .publicAccess)
        return EdgeClient()
    }()
    
    // This is where we store the AI use case deployment information.
    internal var deployedUseCase: EdgeClient.UseCase? {
        get {
            let loadedVersion = LoadConfig.mimikAIUseCaseConfigUrl()
            
            if let data = UserDefaults.standard.object(forKey: kAIUseCaseDeployment) as? Data,
               let deployment = try? JSONDecoder().decode(EdgeClient.UseCase.self, from: data), let storedVersion = deployment.version {

                // Checking against the current use case config url, removing stored info if outdated.
                guard loadedVersion == storedVersion else {
                    print("⚠️ Outdated stored mimik ai use case info found, removing.")
                    UserDefaults.standard.removeObject(forKey: kAIUseCaseDeployment)
                    UserDefaults.standard.synchronize()
                    return nil
                }
            
                print("✅ Stored mimik ai use case deployment info found")
                return deployment
            }
            
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            topTitleStackView()
            
            if selectedModel != nil && startupDone {
                scrollTextView()
                .defaultScrollAnchor(.bottom)
            }
            
            bottomStackView()
        }
        .sheet(isPresented: $showAddModel) {
            SheetView(modelId: selectedModel?.id ?? "", modelObject: selectedModel?.object?.rawValue ?? "", modelUrl: selectedModel?.url ?? "", modelOwnedBy: selectedModel?.ownedBy ?? "", modelExpectedDownloadSize: 0, modelExcludeFromBackup: selectedModel?.excludeFromBackup ?? true, owner: self)
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
                activeNonStream?.cancel()
            }
        }
    }
    
    func scrollTextView() -> some View {
        ScrollView {
            ScrollViewReader { value in
                Text(textToFlow()).font(.title3.weight(.regular)).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.green, lineWidth: 2)
        )
    }
    
    func textToFlow() -> String {
        var text: String = ""
        
        for storedContext in storedLiveContent {
            if let role = storedContext.role, let content = storedContext.content {
                
                if role == "user", text.isEmpty {
                    text = text + "<user> \"" + content + "\"\n\n"
                }
                else if role == "user" {
                    text = text + "\n\n<user> \"" + content + "\"\n\n"
                }
                else  {
                    text = text + content
                }
            }
        }
        
        return text
    }
    
    func topTitleStackView() -> some View {
        VStack(spacing: 0) {
            Image("mimik-ai-logo-black")
            Text("chat").font(.title)
            
            if !startupDone && selectedModel != nil {
                Text("\nmodel warmup.\nplease wait.").fontDesign(.serif)
            }
            else if !startupDone {
                Text("\nmimik ai startup.\nplease wait.").fontDesign(.serif)
            }
        }
    }
    
    func bottomStackView() -> some View {
        VStack(spacing: 20) {
                                        
            if startupDone {
                
                if selectedModel != nil {
                    bottomUserInputView()
                    .disabled(isWaiting)
                    .textFieldModifier(borderColor: userInputColour(), lineWidth: downloadedModels.count >= 1 ? 2 : 1)
                }
                                
                VStack(spacing: 5) {
                    
                    if selectedModel != nil && storedLiveContent.count > 0 {
                        Button("Clear Context", systemImage: "trash", role: .destructive) {
                            clearContext()
                        }
                        .font(manageModelsFont()).frame(maxWidth: .infinity, alignment: .trailing)
                        .disabled(isWaiting)
                        
                        Button("Copy Context", systemImage: "document.on.document", role: .none) {
                            UIPasteboard.general.string = textToFlow()
                        }
                        .font(manageModelsFont()).frame(maxWidth: .infinity, alignment: .trailing)
                        .disabled(isWaiting)
                    }
                }
                

                HStack() {
                    menuView()
                }
                .frame(maxWidth: .infinity, minHeight: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(manageModelsBorderColour(), lineWidth: 2)
                )
            }
            
            if !bottomMessage.isEmpty {
                Text(bottomMessage).fontDesign(.serif)
            }
        }
    }
    
    func bottomUserInputView() -> some View {
        
        HStack {
            TextField("", text: $userInput, prompt: Text(userInputPrompt()).foregroundStyle(userInputStyle())).onSubmit {
                question = userInput
                userInput = ""
                storedResponse = ""
                Task {
                    bottomMessage = ""
                    let clock = ContinuousClock()
                    
                    let elapsed = await clock.measure {
                        
                        if streamResponse {
                            guard case .success(_) = await askAIStream(question: question) else {
                                return
                            }
                        }
                        else {
                            guard case .success(_) = await askAIDirect(question: question) else {
                                return
                            }
                        }
                    }
                    
                    let format = elapsed.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
                    print("Response completion time (min:sec): \(format)")
                    bottomMessage = streamResponse ? "Streamed response time: \(format)" : "Non-streamed response time: \(format)"
                }
            }
        }
    }
    
    func menuView() -> some View {
        VStack(spacing: 10) {
            
            if activeStream == nil && activeNonStream == nil {
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
                            Task {
                                await selectActive(model: model, automatic: false)
                            }
                        }
                    }
                                    
                    Button("Add AI Model", systemImage: "plus") {
                        showAddModel = true
                    }
                    
                    Toggle(streamResponse ? "Streaming is ON" : "Streaming is OFF", isOn: $streamResponse)
                        .toggleStyle(.button)
                    
                    Text("App: \(LoadConfig.versionBuild()), mim OE: \(mimOEVersion)")
                    Text("Token expires on: \(LoadConfig.tokenExpiration())")
                    
                } label: {
                    Label(manageModelsLabel(), systemImage: manageModelsIcon())
                }.font(manageModelsFont()).frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(manageModelsColour())
            }
            else {
                Button("Cancel Request", systemImage: "xmark", role: .destructive) {
                    activeStream?.cancel()
                    activeNonStream?.cancel()
                }.font(manageModelsFont()).frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
