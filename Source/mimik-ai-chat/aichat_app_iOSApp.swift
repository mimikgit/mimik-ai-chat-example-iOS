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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var appState : AppState
    @StateObject private var engineService: EngineService
    @StateObject private var modelService: ModelService
    @StateObject private var authState: AuthState

    init() {
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        let engine = EngineService()
        _engineService = StateObject(wrappedValue: engine)
        let authState = AuthState()
        _authState = StateObject(wrappedValue: authState)
        let model = ModelService(engineService: engine, appState: appState, authState: authState)
        _modelService = StateObject(wrappedValue: model)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(engineService)
                .environmentObject(modelService)
                .environmentObject(authState)
        }
    }
}
