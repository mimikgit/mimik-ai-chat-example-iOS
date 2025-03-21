//
//  ContentView.swift
//

import SwiftUI
import PhotosUI
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
    
    // Photo Picker selection
    @State var selectedImage: UIImage?
    
    // File Picker selection
    @State var selectedFileURL: URL? = nil
    
    // States
    @State internal var isWaiting: Bool = false
    @State internal var startupDone: Bool = false
    @State internal var showSwitchModel: Bool = false
    @Environment(\.scenePhase) var scenePhase
    @State internal var lastUsage: EdgeClient.AI.Model.Usage?
    
    // UI
    @State internal var storedResponse: String = ""
    @State internal var newResponse: String = ""
    @State internal var selectedModelId: String = ""
    @State internal var bottomMessage: String = ""
    
    internal var markdownTextToFlow: AttributedString? {
        return try? AttributedString(markdown: textToFlow(), options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }
    
    // mimik Client Library
    let edgeClient: EdgeClient = {
        EdgeClient.setLoggingLevel(module: .edgeCore, level: .debug, privacy: .publicAccess)
        EdgeClient.setLoggingLevel(module: .edgeEngine, level: .debug, privacy: .publicAccess)
        return EdgeClient()
    }()
    
    // This is where we store the AI use case deployment information.
    internal var deployedUseCase: EdgeClient.UseCase? {
        get {
            guard case let .success(loadedConfig) = ConfigManager.decodeJsonDataFrom(file: "mimik-ai-use-case-config", type: EdgeClient.UseCase.self), let loadedVersion = loadedConfig.version else {
                return nil
            }
                        
            if let data = UserDefaults.standard.object(forKey: kAIUseCaseDeployment) as? Data,
               let deployment = try? JSONDecoder().decode(EdgeClient.UseCase.self, from: data), let storedVersion = deployment.version {

                // Checking against the current use case config url, removing stored info if outdated.
                guard loadedVersion == storedVersion else {
                    print("⚠️ Outdated stored mimik ai use case info found, removing.", "\nloadedVersion:", loadedVersion, "\nstoredVersion:", storedVersion)
                    UserDefaults.standard.removeObject(forKey: kAIUseCaseDeployment)
                    UserDefaults.standard.synchronize()
                    return nil
                }
            
                print("✅ Stored mimik ai use case deployment info found, version:", storedVersion)
                return deployment
            }
            print("⚠️ No stored mimik ai use case deployment found")
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
            
            BottomChatView(owner: self, storedResponse: $storedResponse, startupDone: $startupDone, selectedModel: $selectedModel, isWaiting: $isWaiting, downloadedModels: $downloadedModels, storedLiveContent: $storedLiveContent, selectedImage: $selectedImage, selectedFileURL: $selectedFileURL, activeStream: $activeStream, activeNonStream: $activeNonStream, mimOEVersion: $mimOEVersion, bottomMessage: $bottomMessage, lastUsage: $lastUsage)
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
    
    private func scrollTextView() -> some View {
        ScrollView {
            ScrollViewReader { value in
                Text(markdownTextToFlow ?? "").fontDesign(.monospaced).font(.title3.weight(.regular)).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isWaiting ? .gray : .green, lineWidth: 2)
        )
    }
    
    private func topTitleStackView() -> some View {
        VStack(spacing: 0) {
            Image("mimik-ai-logo-black")
            Text("chat").font(.title)
            
            if !startupDone && selectedModel != nil {
                Text("\nmodel warmup.\nplease wait.").fontDesign(.monospaced)
            }
            else if !startupDone {
                Text("\nmimik ai startup.\nplease wait.").fontDesign(.monospaced)
            }
        }
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
}
