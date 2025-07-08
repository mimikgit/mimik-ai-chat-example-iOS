//
//  MenuViewOnline.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-07-07.
//

import Alamofire
import EdgeCore
import SwiftUI

struct MenuViewOnline: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var engineService: EngineService
    @EnvironmentObject var modelService: ModelService
    
    var body: some View {
        VStack(spacing: 10) {
            Menu {
                Menu("Deactive") {
                    
                    let authorizedServices = modelService.configuredServices(sortedFirstBy: .gemini).filter { service in
                        authState.accessToken(serviceKind: service.kind, tokenType: .developerToken) != nil
                    }
                    
                    ForEach(authorizedServices, id: \.modelId) { service in
                        
                        Button("Deactivate \(service.kind.rawValue)", systemImage: "trash", role: .destructive) {
                            Task {
                                print("\(service.id) de-activation")
                                appState.tokenInputService = nil
                                authState.deleteServiceToken(serviceKind: service.kind)
                                modelService.reAuthorizeServices()
                            }
                        }
                    }
                    
                                        
                    Button("Remove Everything", systemImage: "trash.fill", role: .destructive) {
                        Task {
                            appState.generalMessage = "Please Wait..."
                            try await engineService.removeEverything()
                            
                            appState.stateReset()
                            authState.deleteAllTokens()
                        }
                    }
                }
                                
                let unauthorizedServices = modelService.configuredServices(sortedFirstBy: .gemini).filter { service in
                    authState.accessToken(serviceKind: service.kind, tokenType: .developerToken) == nil
                }
                
                ForEach(unauthorizedServices, id: \.modelId) { service in
                    
                    Button("Activate \(service.kind.rawValue)", systemImage: "plus") {
                        Task {
                            print("\(service.id) activation")
                            appState.tokenInputService = service
                        }
                    }
                }
                
                Text("App: \(ConfigService.versionBuild()), mim OE: \(engineService.mimOEVersion)")
                Text("Token expires on: \(ConfigService.tokenExpiration())")
                
            } label: {
                VStack {
                    MetallicText(text: isValidationReady ? validationServiceName : "Online", fontSize: DeviceType.isTablet ? 28 : 12, color: .silver)
                    MetallicText(text: "Validation", fontSize: DeviceType.isTablet ? 28 : 12, color: .amethyst)
                    MetallicText(text: infoLabel(), fontSize: DeviceType.isTablet ? 32 : 12, color: infoLabelColour(), icon: "gear.badge", iconPosition: .after)
                }
            }
        }
    }
    
    private var isValidationReady: Bool {
        guard let service = modelService.primaryValidateService else {
            return false
        }
        return authState
            .accessToken(serviceKind: service.kind, tokenType: .developerToken) != nil
    }
    
    private var validationServiceName: String {
        guard let service = modelService.primaryValidateService else {
            return ""
        }
        return service.kind.rawValue
    }
    
    private func infoLabel() -> String {
        isValidationReady ? "READY" : "OFFLINE"
    }
    
    func infoLabelColour() -> MetallicText.MetallicColor {
        isValidationReady ? .gold : .obsidian
    }
}
