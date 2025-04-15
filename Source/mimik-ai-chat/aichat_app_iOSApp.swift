//
//  aichat_app_iOSApp.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-01.
//

import EdgeCore
import SwiftUI

@main
struct aichat_app_iOSApp: App {
    
    @StateObject private var appState : StateService
    @StateObject private var engineService: EngineService
    @StateObject private var modelService: ModelService

    init() {
        let appState = StateService()
        _appState = StateObject(wrappedValue: appState)
        let engine = EngineService()
        _engineService = StateObject(wrappedValue: engine)
        let model = ModelService(engineService: engine, appState: appState)
        _modelService = StateObject(wrappedValue: model)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(engineService)
                .environmentObject(modelService)
        }
    }
}
