//
//  Untitled.swift
//  mimik-ai-chat
//
//  Created by rb on 2024-10-30.
//

import EdgeCore
import EdgeEngine

extension SheetView {
    
    func currentPreset() -> EdgeClient.AI.Model.CreateModelRequest? {
        
        guard !modelId.isEmpty, !modelObject.isEmpty, !modelUrl.isEmpty else {
            return nil
        }
        
        let preset: EdgeClient.AI.Model.CreateModelRequest = EdgeClient.AI.Model.CreateModelRequest(id: modelId, object: modelObject, url: modelUrl, expectedDownloadSize: modelExpectedDownloadSize, ownedBy: modelOwnedBy)
        return preset
    }
    
    private func filenameForModel(number: Int) -> String {
        switch number {
        case 1:
            return "config-ai-model1-download"
        case 2:
            return "config-ai-model2-download"
        case 3:
            return "config-ai-model3-download"
        case 4:
            return "config-ai-model4-download"
            
        default:
            return "config-ai-model1-download"
        }
    }
    
    func loadPreset(number: Int) {
        
        guard let model = LoadConfig.aiModelRequest(file: filenameForModel(number: number)) else {
            return
        }
        
        modelId = model.id
        modelObject = model.object
        modelUrl = model.url
        modelOwnedBy = model.ownedBy ?? ""
        modelExpectedDownloadSize = model.expectedDownloadSize
    }
}
