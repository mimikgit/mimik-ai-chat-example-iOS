//
//  ModelService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-02.
//

import EdgeCore
import SwiftUI

extension ModelService {
    
    func groupedServices(for serviceType: ServiceType) -> [(provider: String, models: [EdgeClient.AI.ServiceConfiguration])] {
        
        // if prompt is using a VLM model, or if it was not set yet, offer no validation services
        if serviceType == .validation,
           (selectedPromptService == nil || selectedPromptService?.model?.kind == .vlm) {
            return []
        }
        
        // keep only the services we’re actually authorized to use
        let authorized = configuredServices.filter { service in
            authState.accessToken(
                serviceKind: service.kind,
                tokenType: .developerToken
            ) != nil
        }
        
        // don't included any services already assigned to either picker
        let excludedServices = [selectedPromptService, selectedValidateService]
            .compactMap { $0 }
        
        // start with authorized & not‐already‐selected
        var eligible = authorized.filter { service in
            !excludedServices.contains(service)
        }
        
        // drop any models explicitly marked readyToUse == false
        eligible = eligible.filter { config in
            // if readyToUse is nil or true, keep it; if false, drop it
            return config.model?.readyToUse ?? true
        }
        
        // if we’re building the validation list, drop all .vlm‐model services
        if serviceType == .validation {
            eligible = eligible.filter { config in
                config.model?.kind != .vlm
            }
        }
        
        let grouped = Dictionary(grouping: eligible) { $0.kind.rawValue }
        
        return grouped
            .map { provider, models in
                ( provider: provider,
                  models: models.sorted {
                    ($0.modelId ?? "") < ($1.modelId ?? "")
                  }
                )
            }
            .sorted { $0.provider < $1.provider }
    }
    
    @MainActor
    func updateConfiguredServices() async {
        configuredServices.removeAll()
        try? await Task.sleep(nanoseconds: 250_000_000)

        if let config = mimikAiConfiguration {
            
            let client = EdgeClient.AI.HybridClient(configuration: config, hybridEdgeClient:  engineService.hybridEdgeClient)
            if case let .success(models) = await client.availableModels() {

                let readyModels = models.filter { $0.readyToUse ?? true }
                
                readyModels.forEach { model in
                    configuredServices.addOrReplace(.init(kind: .mimikAI, model: model, apiKey: authState.accessToken(serviceKind: .mimikAI, tokenType: .developerToken), mimOEPort: engineService.edgeClient.edgeEngineFullPathUrl().port, mimOEClientId: engineService.mimOEClientId))
                }
            } else {
                print("⚠️ Failed to fetch models")
            }
        }

        let model = EdgeClient.AI.Model.init(id: "gemini-2.0-flash", kind: .llm)
        configuredServices.addOrReplace((.init(kind: .gemini, model: model, apiKey: authState.accessToken(serviceKind: .gemini, tokenType: .developerToken), mimOEPort: nil, mimOEClientId: nil)))
        
        try? await updateDownloadedModels()
        
        for service in configuredServices {
            print("✅ \(service.kind.rawValue): \(service.model?.id ?? "⚠️") : \(service.apiKey ?? "⚠️")")
        }
    }
    
    func configuredServices(sortedFirstBy preferredKind: EdgeClient.AI.ServiceConfiguration.Kind) -> [EdgeClient.AI.ServiceConfiguration] {
        return configuredServices.sorted { lhs, rhs in
            if lhs.kind == preferredKind && rhs.kind != preferredKind { return true }
            if lhs.kind != preferredKind && rhs.kind == preferredKind { return false }
            return lhs.id < rhs.id
        }
    }
    
    func configuredServices(uniqueByKindWithPreferred preferredKind: EdgeClient.AI.ServiceConfiguration.Kind) -> [EdgeClient.AI.ServiceConfiguration] {
        let sorted = configuredServices(sortedFirstBy: preferredKind)
        var seenKinds = Set<EdgeClient.AI.ServiceConfiguration.Kind>()
        return sorted.filter { config in
            seenKinds.insert(config.kind).inserted
        }
    }
    
    func configuredServicesByKind() -> [EdgeClient.AI.ServiceConfiguration] {
        var seenKinds = Set<EdgeClient.AI.ServiceConfiguration.Kind>()
        return configuredServices.filter { seenKinds.insert($0.kind).inserted }
    }
}
