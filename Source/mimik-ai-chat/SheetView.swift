//
//  SheetView.swift
//

import SwiftUI
import EdgeCore
import Alamofire
import SwiftyJSON

struct SheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State internal var modelId: String
    @State internal var modelObject: String
    @State internal var modelUrl: String
    @State internal var modelOwnedBy: String
    @State internal var modelExpectedDownloadSize: Int64
    @State internal var owner: ContentView
    
    init(modelId: String, modelObject: String, modelUrl: String, modelOwnedBy: String, modelExpectedDownloadSize: Int64, owner: ContentView) {
        self.modelId = modelId
        self.modelObject = modelObject
        self.modelUrl = modelUrl
        self.modelOwnedBy = modelOwnedBy
        self.modelExpectedDownloadSize = modelExpectedDownloadSize
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
                    Text("gemma-v1.1-2b")
                }
                
                Spacer()
                
                Button {
                    loadPreset(number: 2)
                } label: {
                    Text("gemma-v2-2b")
                }
                                                                
                Spacer()

                
            }.frame(maxWidth: .infinity, minHeight: 20)
                .padding()
                        
            VStack(alignment: .leading) {
                Text("Model ID").font(.subheadline.weight(.light)).foregroundColor(.gray)
                TextField("", text: $modelId)
                    .textFieldModifier()
            }.padding()
            
            VStack(alignment: .leading) {
                Text("Model Object").font(.subheadline.weight(.light)).foregroundColor(.gray)
                TextField("", text: $modelObject)
                    .textFieldModifier()
            }.padding()
            
            VStack(alignment: .leading) {
                Text("Model URL").font(.subheadline.weight(.light)).foregroundColor(.gray)
                TextField("", text: $modelUrl)
                    .textFieldModifier()
            }.padding()
            
            VStack(alignment: .leading) {
                Text("Model Owned By").font(.subheadline.weight(.light)).foregroundColor(.gray)
                TextField("", text: $modelOwnedBy)
                    .textFieldModifier()
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
            
            owner.menuLabel = ""
            let clock = ContinuousClock()
            var errorMessage: String = ""
            
            let elapsed = await clock.measure {
                guard let configUrl = LoadConfig.mimikAIUseCaseConfigUrl(), case let .success(change) = await owner.integrateAI(useCaseConfigUrl: configUrl, model: model) else {
                    errorMessage = "Download Error"
                    return
                }
                
                guard let apiKey = LoadConfig.mimikAIUseApiKey(), let useCase = owner.deployedUseCase, case let .success(models) = await owner.edgeClient.aiModels(accessToken: owner.mimOEAccessToken, apiKey: apiKey, useCase: useCase), !models.isEmpty else {
                    errorMessage = "Configuration Error"
                    return
                }
                
                if change {
                    await owner.processAvailableAIModels()
                }
            }
            
            let format = elapsed.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            print("⏱️⏱️⏱️ Download completion time (min:sec): \(format)")
            
            owner.menuLabel = errorMessage.isEmpty ? "Download completion time (min:sec):\n\(format)" : errorMessage
        }
    }
}
