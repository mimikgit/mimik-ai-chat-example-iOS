//
//  AddModelView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-17.
//

import SwiftUI
import EdgeCore
import Alamofire
import SwiftyJSON

struct AddModelView: View {
        
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var engineService: EngineService
    @EnvironmentObject var modelService: ModelService
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var modModel: AddModelView.ModifiedModel = .init(id: "", object: "", url: "", mmprojUrl: "", chatHint: "", ownedBy: "", kind: "", excludeFromBackup: true, expectedDownloadSize: 0)
    
    struct ModifiedModel {
        var id: String
        var object: String
        var url: String
        var mmprojUrl: String
        var chatHint: String
        var ownedBy: String
        var kind: String
        var excludeFromBackup: Bool
        var expectedDownloadSize: Int64
        
        static func readableFileSize(_ bytes: Int64) -> String {
            let units = ["B", "KB", "MB", "GB", "TB"]
            var size = Double(bytes)
            var unitIndex = 0

            while size >= 1000 && unitIndex < units.count - 1 {
                size /= 1000
                unitIndex += 1
            }

            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = (size < 10) ? 2 : (size < 100 ? 1 : 0)
            formatter.minimumFractionDigits = 0
            formatter.numberStyle = .decimal

            let sizeString = formatter.string(from: NSNumber(value: size)) ?? "\(size)"
            return "\(sizeString) \(units[unitIndex])"
        }
    }
    
    var body: some View {
                
        ZStack() {
            
            VStack(spacing: DeviceType.isTablet ? 30 : 40) {
                
                VStack {
                    HStack {
                        Spacer()
                        MetallicText(text: "SELECT A MODEL", fontSize: DeviceType.isTablet ? 25 : 20, color: .silver, icon: "arrow.turn.right.down", iconPosition: .after)
                        Spacer()
                    }
                    .padding()
                    .padding(.top, DeviceType.isTablet ? 20 : 20)
                                        
                    modelScroll
                        .frame(maxWidth: DeviceType.isTablet ? 426 : ScreenSize.screenWidth * 0.9, maxHeight: DeviceType.isTablet ? 240 : 120)
                        .padding([.leading, .trailing])
                }
                
                downloadButton
                                
                textfieldsStack
                    .frame(maxWidth: DeviceType.isTablet ? 460 : ScreenSize.screenWidth * 0.9)
                    .padding(.bottom, DeviceType.isTablet ? 40 : 0)
                    .padding([.leading, .trailing], DeviceType.isTablet ? 40 : 20)
            }
        }
        .task {
            loadPreset(decodedModel: ConfigService.modelPresets().first)
        }
    }
    
    private var downloadButton: some View {
        let isDownloaded = appState.alreadyDownloadedModel(id: modModel.id)
        let buttonText = isDownloaded ? "ALREADY DOWNLOADED" : "START DOWNLOAD (\(ModifiedModel.readableFileSize(modModel.expectedDownloadSize)))"
        
        let backgroundColor = isDownloaded ? Color(UIColor.gray) : Color(UIColor.systemRed)
        
        let action: () -> Void = isDownloaded ? {} : {
                Task {
                    await nextTask()
                }
            }

        return ModelButton(buttonText: buttonText, backgroundColor: backgroundColor, foregroundColor: .white, fontSize: DeviceType.isTablet ? 22 : 20, maxWidth: DeviceType.isTablet ? 426 : ScreenSize.screenWidth * 0.8, maxHeight: DeviceType.isTablet ? 60 : 50, action: action
        )
    }
    
    private var modelScroll: some View {
        
        ScrollViewReader { proxy in
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    ForEach(ConfigService.modelPresets().indices, id: \.self) { index in
                        
                        if let selection = ConfigService.modelPresets()[index] as EdgeClient.AI.Model.CreateModelRequest?, selection.id == modModel.id {
                            
                            ModelButton(buttonText: ConfigService.modelPresets()[index].shortDescription, backgroundColor: Color(UIColor.systemBlue).opacity(1.0), foregroundColor: .white, fontSize: DeviceType.isTablet ? 17 : 21, maxWidth: DeviceType.isTablet ? 426 : ScreenSize.screenWidth * 0.8, maxHeight: DeviceType.isTablet ? 60 :50, model: ConfigService.modelPresets()[index]) {
                                Task {
                                    loadPreset(decodedModel: ConfigService.modelPresets()[index])
                                }
                            }
                        }
                        else {
                            ModelButton(buttonText: ConfigService.modelPresets()[index].shortDescription, backgroundColor: Color(UIColor.systemBlue).opacity(0.6), foregroundColor: .white.opacity(0.6), fontSize: DeviceType.isTablet ? 17 : 21, maxWidth: DeviceType.isTablet ? 426 : ScreenSize.screenWidth * 0.8, maxHeight: DeviceType.isTablet ? 60 : 50, model: ConfigService.modelPresets()[index]) {
                                Task {
                                    loadPreset(decodedModel: ConfigService.modelPresets()[index])
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 25_000_000)
                    
                    withAnimation {
                          proxy.scrollTo(ConfigService.modelPresets().count - 1, anchor: .bottom)
                    }
                    
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    withAnimation {
                        proxy.scrollTo(0, anchor: .top)
                    }
                }
            }
        }
    }
    
    private var textfieldsStack: some View {
        
        VStack(spacing: 24) {
            LabeledTextField(label: "Model Id", placeholder: "", text: $modModel.id, fontSize:  DeviceType.isTablet ? 15 : 13, labelColor: .silver, textColor: .white, borderColor: .white.opacity(0.7), cornerRadius: 15.0, borderWidth: 3.0, backgroundColor: .clear)
                        
            LabeledTextField(label: "Model Url", placeholder: "", text: $modModel.url, fontSize:  DeviceType.isTablet ? 15 : 13, labelColor: .silver, textColor: .white, borderColor: .white.opacity(0.7), cornerRadius: 15.0, borderWidth: 3.0, backgroundColor: .clear)
            
            LabeledTextField(label: "Model Projection Url (vlm only)", placeholder: "", text: $modModel.mmprojUrl, fontSize:  DeviceType.isTablet ? 15 : 13, labelColor: .silver, textColor: .white, borderColor: .white.opacity(0.7), cornerRadius: 15.0, borderWidth: 3.0, backgroundColor: .clear).disabled(modModel.mmprojUrl.isEmpty).opacity(modModel.mmprojUrl.isEmpty ? 0 : 1)
        }
    }
    
    private func nextTask() async {
        presentationMode.wrappedValue.dismiss()
        
        guard let model = currentPreset() else {
            appState.generalMessage = "Configuration Error"
            return
        }
        
        appState.generalMessage = ""
        
        do {
            let clock = ContinuousClock()
            
            let elapsed = try await clock.measure {
                if let useCase = engineService.deployedUseCase {
                    // Already have Use Case deployed
                    try await downloadTask(useCase: useCase, model: model)
                }
                else {
                    // No Deployed Use Case
                    try await deployTask(model: model)
                    if let useCase = engineService.deployedUseCase {
                        try await downloadTask(useCase: useCase, model: model)
                    }
                }
            }
            
            let format = elapsed.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            print("Download completed in: \(format)")
            appState.generalMessage = "Download completed in: \(format)"
        }
        
        catch let error as NSError {
            if error.localizedDescription.contains("cancelled") {
                appState.generalMessage = error.localizedDescription
                return
            }
            
            appState.generalMessage = error.domain
        }
    }
    
    private func deployTask(model: EdgeClient.AI.Model.CreateModelRequest) async throws {
        
        do {
            guard case let .success(config) = ConfigService.decodeJsonDataFrom(file: "mimik-ai-use-case-config", type: EdgeClient.UseCase.self) else {
                throw NSError(domain: "Integration Failed", code: 500)
            }
            
            try await modelService.integrateAI(useCase: config)
        }
        
        catch let error as NSError {
            appState.generalMessage = error.domain
            throw error
        }
    }
    
    private func downloadTask(useCase: EdgeClient.UseCase, model: EdgeClient.AI.Model.CreateModelRequest) async throws {
        
        guard let model = currentPreset(), let apiKey = ConfigService.fetchConfig(for: .milmApiKey) else {
            return
        }
        
        // Calling mimik Client Library to download the AI language model using the mILM edge microservice that was deployed as part of the mimik ai use case
        switch await engineService.edgeClient.downloadAI(model: model, accessToken: engineService.mimOEAccessToken, apiKey: apiKey, useCase: useCase, downloadHandler: { download in
            
            guard case let .success(downloadProgress) = download else {
                print("⚠️ No model download progress")
                return
            }
            
            let percent = String(format: "%.2f", ceil( (downloadProgress.size / downloadProgress.totalSize) * 10_000) / 100)
            let line = "Model download progress: " + "\(percent)％ Don't lock your device. Keep this app open."
            print("⚠️ Model download progress: " + percent)
            
            if line.contains("100.00") {
                appState.justDownloadedModelId = model.id
            }
            else {
                appState.generalMessage = line
                appState.justDownloadedModelId = ""
            }
            
        }, requestHandler: { request in
            // Keeping the reference to the AI language model download request, in case we want to examine its state or cancel it before it ends.
            DispatchQueue.main.async {
                print("⚠️ Model download request", request)
                appState.activeStream = request
                appState.generalMessage = "Download starting..."
            }
        }) {
            
        case .success:
            
            guard let apiKey = ConfigService.fetchConfig(for: .milmApiKey), case .success = await engineService.edgeClient.aiModel(id: model.id, accessToken: engineService.mimOEAccessToken, apiKey: apiKey, useCase: useCase) else {
                print("Model download claims success, but IDs don't match")
                appState.activeStream = nil
                throw NSError(domain: "Download Failed", code: 500)
            }
                        
            // AI language model download request successful
            appState.generalMessage = "Download successful, please wait."
            // Clearing out the AI language model download request reference
            appState.activeStream = nil
            
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await modelService.processAvailableAIModels()
            }
            
        case .failure(let error):
            print("Model download error", error.localizedDescription)
            appState.activeStream = nil
            throw error
        }
    }
    
    private func currentPreset() -> EdgeClient.AI.Model.CreateModelRequest? {
        
        guard !modModel.id.isEmpty, !modModel.object.isEmpty, !modModel.url.isEmpty else {
            return nil
        }
        
        let template = EdgeClient.AI.Model.CreateModelRequest.ChatTemplateHint.init(rawValue: modModel.chatHint)
        
        let preset = EdgeClient.AI.Model.CreateModelRequest(id: modModel.id, object: modModel.object, url: modModel.url, expectedDownloadSize: modModel.expectedDownloadSize, kind: EdgeClient.AI.Model.Kind(rawValue: modModel.kind) ?? .llm, chatTemplateHint: template, mmprojUrl: modModel.mmprojUrl, ownedBy: modModel.ownedBy, excludeFromBackup: modModel.excludeFromBackup)
        return preset
    }
    
    private func loadPreset(decodedModel: EdgeClient.AI.Model.CreateModelRequest?) {
        
        guard let decodedModel = decodedModel else {
            print("⚠️ Decoded model missing")
            return
        }
        
        let model: AddModelView.ModifiedModel = AddModelView.ModifiedModel.init(id: decodedModel.id, object: decodedModel.object, url: decodedModel.url, mmprojUrl: decodedModel.mmprojUrl ?? "", chatHint: decodedModel.chatTemplateHint?.rawValue ?? "", ownedBy: decodedModel.ownedBy ?? "", kind: decodedModel.kind?.rawValue ?? "llm", excludeFromBackup: decodedModel.excludeFromBackup ?? true, expectedDownloadSize: decodedModel.expectedDownloadSize)
        modModel = model
    }
}
