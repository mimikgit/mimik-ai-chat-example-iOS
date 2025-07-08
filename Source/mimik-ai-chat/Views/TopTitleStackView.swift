//
//  TopTitleStackView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-21.
//

import Alamofire
import EdgeCore
import SwiftUI

struct TopTitleStackView: View {
    
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var modelService: ModelService
    @EnvironmentObject private var appState: AppState
    @State private var showAddModelTablet: Bool = false
    @State private var showAddModelPhone: Bool = false
    @State private var validationSelections: Set<EdgeClient.AI.ServiceConfiguration> = []
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                if appState.downloadedModels.count > 0 {
                    haveModelsMenu
                }
                else {
                    noModelsMenu
                }
            }
        }
    }
    
    private var noModelsMenu: some View {
        VStack(spacing: 0) {
            Image("mimik-ai-logo-white")
            MetallicText(text: "agentix playground", fontSize: 18, color: .amethyst)
            menuViewOnDevice.disabled(appState.activeStream != nil)
            
            if !appState.generalMessage.isEmpty {
                Spacer()
                HStack {
                    if appState.activeStream != nil {
                        MetallicText(text: "", fontSize: DeviceType.isTablet ? 25 : 16, color: .ruby, icon: "xmark", iconPosition: .after) { appState.resetContextState() }
                    }
                    MetallicText(text: appState.generalMessage, fontSize: DeviceType.isTablet ? 23 : 23, color: .silver, lineLimit: .init(lineLimit: DeviceType.isTablet ? 2 : 4, reservesSpace: DeviceType.isTablet ? false : true))
                }
            }
        }
    }
    
    private var haveModelsMenu: some View {        
        VStack {
            HStack() {
                menuViewOnDevice
                    .customBackground(backgroundColor: Color(UIColor.systemFill), cornerRadius: 15)
                
                Spacer()
                
                VStack {
                    Image("mimik-ai-logo-white")
                    MetallicText(text: "agentix", fontSize: DeviceType.isTablet ? 18 : 10, color: .amethyst)
                    MetallicText(text: "playground", fontSize: DeviceType.isTablet ? 18 : 10, color: .amethyst)
                }
             
                Spacer()
                
                menuViewOnline
                    .customBackground(backgroundColor: Color(UIColor.systemFill), cornerRadius: 15)
            }
        }
    }
    
    private var menuViewOnDevice: some View {
        MenuViewOnDevice(showAddModelTablet: $showAddModelTablet, showAddModelPhone: $showAddModelPhone)
    }

    private var menuViewOnline: some View {
        MenuViewOnline()
    }
    
    private func manageModelsBorderColour() -> Color {
        
        if appState.downloadedModels.isEmpty || appState.selectedModel == nil {
            return .clear
        }
        
        if appState.activeStream != nil {
            return .gray
        }
        
        return .blue
    }
}
