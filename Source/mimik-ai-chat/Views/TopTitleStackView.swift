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
    
    @EnvironmentObject private var appState: StateService
    @State private var showAddModelTablet: Bool = false
    @State private var showAddModelPhone: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            if appState.downloadedModels.count > 0 {
                haveModelsMenu
            }
            else {
                noModelsMenu
            }
        }
    }
    
    private var noModelsMenu: some View {
        VStack(spacing: 0) {
            Image("mimik-ai-logo-white")
            MetallicText(text: "agentix playground", fontSize: 18, color: .amethyst)
            menuView.disabled(appState.activeStream != nil)
            
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
        HStack() {
            menuView
                .customBackground(backgroundColor: Color(UIColor.systemFill), cornerRadius: 15)
                .frame(maxWidth: ScreenSize.screenWidth * 0.3, alignment: .trailing)
                        
            VStack(spacing: 0) {
                Image("mimik-ai-logo-white")
                MetallicText(text: "agentix playground", fontSize: DeviceType.isTablet ? 18 : 10, color: .amethyst)
            }
            .frame(maxWidth: ScreenSize.screenWidth * 0.3, alignment: .center)
            
            if let url = URL(string: "https://mimik.ai") {
                MetallicText(text: DeviceType.isTablet ? "visit mimik.ai" : "mimik.ai", fontSize: DeviceType.isTablet ? 32 : 16, color: .gold) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                .customBackground(backgroundColor: Color(UIColor.systemFill), cornerRadius: 15)
                .frame(maxWidth: ScreenSize.screenWidth * 0.3, alignment: .leading)
            }
        }
    }
    
    private var menuView: some View {
        MenuView(showAddModelTablet: $showAddModelTablet, showAddModelPhone: $showAddModelPhone)
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
