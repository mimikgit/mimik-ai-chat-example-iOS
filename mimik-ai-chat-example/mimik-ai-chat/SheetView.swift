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
                
                Button("Cancel", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                Button {
                    loadPreset1()
                } label: {
                    Text("Default Settings")
                }
                
                Spacer()
                
                Button("Cancel", role: .destructive) {}
                    .hidden()
                
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
                
                Task {
                    presentationMode.wrappedValue.dismiss()
                    guard let model = LoadConfig.aiModelRequest() else {
                        return
                    }
                    
                    guard let configUrl = LoadConfig.mimikAIUseCaseConfigUrl(), case let .success(change) = await owner.integrateAI(useCaseConfigUrl: configUrl, model: model) else {
                        return
                    }
                    
                    guard let apiKey = LoadConfig.mimikAIUseApiKey(), let useCase = owner.useCaseDeployment?.useCase, case let .success(models) = await owner.edgeClient.availableAIModels(accessToken: owner.mimOEAccessToken, apiKey: apiKey, useCase: useCase), !models.isEmpty else {
                        return
                    }
                    
                    if change {
                        await owner.processAvailableAIModels()
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundColor(.white)
            .background(.red)
            .cornerRadius(10.0)
            .padding()
        }
        .padding()
        .task {
            loadPreset1()
        }
    }
    
    private func loadPreset1() {
        
        guard let model = LoadConfig.aiModelRequest() else {
            return
        }
        
        modelId = model.id
        modelObject = model.object
        modelUrl = model.url
        modelOwnedBy = model.ownedBy ?? ""
        modelExpectedDownloadSize = model.expectedDownloadSize
    }
}
