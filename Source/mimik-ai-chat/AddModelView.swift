//
//  AddModelView.swift
//

import SwiftUI
import EdgeCore
import Alamofire
import SwiftyJSON

struct AddModelView: View {
        
    struct Model {
        var id: String
        var object: String
        var url: String
        var mmprojUrl: String
        var chatHint: String
        var ownedBy: String
        var kind: String
        var excludeFromBackup: Bool
        var expectedDownloadSize: Int64
    }
    
    @State private var model: AddModelView.Model
    
    @Environment(\.presentationMode) var presentationMode
    @State internal var owner: ContentView
    
    init(model: AddModelView.Model, owner: ContentView) {
        self.model = model
        self.owner = owner
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack(alignment: .top) {
                
                Spacer()
                
                Button("Cancel", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                                
                Button {
                    loadPreset(number: 1)
                } label: {
                    Text("gemma-1.1-2b")
                }
                
                Spacer()
                
                Button {
                    loadPreset(number: 2)
                } label: {
                    Text("gemma-2-2b")
                }
                
                Spacer()
                
                if (ProcessInfo.processInfo.isiOSAppOnMac) {
                    Button {
                        loadPreset(number: 3)
                    } label: {
                        Text("Llama-3.2-3B-Mac").lineLimit(3, reservesSpace: true)
                    }
                             
                    Spacer()
                    
                    Button {
                        loadPreset(number: 4)
                    } label: {
                        Text("Mistral-7B-Mac").lineLimit(3, reservesSpace: true)
                    }
                    
                    Spacer()
                    
                    Button {
                        loadPreset(number: 5)
                    } label: {
                        Text("Llava-v1.5-7B-vlm-Mac").lineLimit(3, reservesSpace: true)
                    }
                    
                    Spacer()
                }

            }.frame(maxWidth: .infinity, minHeight: 20)
                .padding()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Model Kind").font(.subheadline.weight(.light)).foregroundColor(.gray)
                    TextField("", text: $model.kind)
                        .textFieldModifier()
                        .disabled(true)
                }.padding()

                VStack(alignment: .trailing) {
                    Text("Model Template").font(.subheadline.weight(.light)).foregroundColor(.gray)
                    TextField("", text: $model.chatHint)
                        .textFieldModifier()
                        .disabled(true)
                }.padding()
            }
                                    
            VStack(alignment: .leading) {
                Text("Model ID").font(.subheadline.weight(.light)).foregroundColor(.gray)
                TextField("", text: $model.id)
                    .textFieldModifier()
            }.padding()
            
            VStack(alignment: .leading) {
                Text("Model URL").font(.subheadline.weight(.light)).foregroundColor(.gray)
                TextField("", text: $model.url)
                    .textFieldModifier()
            }.padding()
            
            VStack(alignment: .leading) {
                Text("Model Projection URL (VLM Only)").font(.subheadline.weight(.light)).foregroundColor(.gray)
                TextField("", text: $model.mmprojUrl)
                    .textFieldModifier()
                    .disabled(model.kind != "vlm")
            }.padding()
                        
            VStack(alignment: .leading) {
                Text("Expected download size: \(model.expectedDownloadSize) bytes").font(.subheadline.weight(.light)).foregroundColor(.gray)
            }.padding()

            Button("START DOWNLOAD") {
                downloadTask()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundColor(.white)
            .background(.red)
            .cornerRadius(10.0)
            .padding()
        }
        .padding()
        .task {
            loadPreset(number: 1)
        }
    }
    
    func downloadTask() {
        Task {
            presentationMode.wrappedValue.dismiss()
            guard let model = currentPreset() else {
                return
            }
            
            owner.bottomMessage = ""
            let clock = ContinuousClock()
            var errorMessage: String = ""
            
            let elapsed = await clock.measure {
                guard case let .success(config) = ConfigManager.decodeJsonDataFrom(file: "mimik-ai-use-case-config", type: EdgeClient.UseCase.self), case let .success(change) = await owner.integrateAI(useCase: config, model: model) else {
                    errorMessage = "Download Error"
                    return
                }
                
                guard let apiKey = ConfigManager.fetchConfig(for: .milmApiKey), let useCase = owner.deployedUseCase, case let .success(models) = await owner.edgeClient.aiModels(accessToken: owner.mimOEAccessToken, apiKey: apiKey, useCase: useCase), !models.isEmpty else {
                    errorMessage = "Configuration Error"
                    return
                }
                
                if change {
                    await owner.processAvailableAIModels()
                }
            }
            
            let format = elapsed.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            print("⏱️⏱️⏱️ Download completion time (min:sec): \(format)")
            
            owner.bottomMessage = errorMessage.isEmpty ? "Download completed in: \(format)" : errorMessage
        }
    }
    
    func currentPreset() -> EdgeClient.AI.Model.CreateModelRequest? {
        
        guard !model.id.isEmpty, !model.object.isEmpty, !model.url.isEmpty else {
            return nil
        }
        
        let template = EdgeClient.AI.Model.CreateModelRequest.ChatTemplateHint.init(rawValue: model.chatHint)
        
        let preset = EdgeClient.AI.Model.CreateModelRequest(id: model.id, object: model.object, url: model.url, expectedDownloadSize: model.expectedDownloadSize, kind: EdgeClient.AI.Model.Kind(rawValue: model.kind) ?? .llm, chatTemplateHint: template, mmprojUrl: model.mmprojUrl, ownedBy: model.ownedBy, excludeFromBackup: model.excludeFromBackup)
        return preset
    }
    
    private func filenameForModel(number: Int) -> String {
        return "config-ai-model\(number)-download"
    }
    
    func loadPreset(number: Int) {
        
        guard case let .success(decodedModel) = ConfigManager.decodeJsonDataFrom(file: filenameForModel(number: number), type: EdgeClient.AI.Model.CreateModelRequest.self) else {
            return
        }
        
        print("loadPreset model \(number): \(model)")
        
        model.kind = decodedModel.kind?.rawValue ?? "llm"
        model.id = decodedModel.id
        model.object = decodedModel.object
        model.url = decodedModel.url
        model.mmprojUrl = decodedModel.mmprojUrl ?? ""
        model.chatHint = decodedModel.chatTemplateHint?.rawValue ?? ""
        model.ownedBy = decodedModel.ownedBy ?? ""
        model.expectedDownloadSize = decodedModel.expectedDownloadSize
        model.excludeFromBackup = decodedModel.excludeFromBackup ?? true
    }
}
