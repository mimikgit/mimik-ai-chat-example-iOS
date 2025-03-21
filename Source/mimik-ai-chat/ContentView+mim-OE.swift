//
//  ContentView+MimOE.swift
//

import Alamofire
import EdgeCore
import EdgeEngine
import SwiftUI
import SwiftyJSON

extension ContentView {
    
    /// Runs the mim OE startup procedure. Authenticates mim OE using a developer id token, saves the access token from the result. Checks for any available AI models.
    func startupProcedure() async -> Result<Void, NSError> {
        
        guard case .success = await startMimOE() else {
            storedResponse = "mim OE startup error"
            return .failure(NSError(domain: "mim OE startup error", code: 500))
        }
        
        guard case let .success(token) = await authenticateMimOE(), case let .success(version) = await mimOEInfo() else {
            storedResponse = "mim OE authentication error"
            return .failure(NSError(domain: "mim OE authentication error", code: 500))
        }
        
        mimOEAccessToken = token
        mimOEVersion = version
        
        print("✅ mim OE access token:", mimOEAccessToken)
        print("✅ mim OE version:", mimOEVersion)
        
        if let apiKey = ConfigManager.fetchConfig(for: .milmApiKey), let useCase = deployedUseCase, case let .success(models) = await self.edgeClient.aiModels(accessToken: mimOEAccessToken, apiKey: apiKey, useCase: useCase), !models.isEmpty {
            await processAvailableAIModels()
            return .success(())
        }
        else {
            print("⚠️ No AI models have been downloaded.")
            bottomMessage = ""
            return .success(())
        }
    }
    
    /// Starts mim OE.
    private func startMimOE() async -> Result<Void, NSError> {
        
        guard let edgeLicense = ConfigManager.fetchConfig(for: .mimOELicense) else {
            print("⚠️ mim OE license error")
            return .failure(NSError(domain: "mim OE license error", code: 500))
        }

        // Configuring the StartupParameters object with the developer edge license.
        let startupParameters = EdgeClient.StartupParameters(license: edgeLicense, logLevel: .off)

        // Calling mimik Client Library method to starting mim OE asynchronously, waiting for the result.
        switch await self.edgeClient.startEdgeEngine(parameters: startupParameters) {
        case .success:
            print("✅ Starting mim  OE successful")
            // Startup successful, returning success.
            return .success(())
        case .failure(let error):
            print("⚠️ Starting mim OE error", error.localizedDescription)
            // Startup unsuccessful, returning failure.
            return .failure(error)
        }
    }
    
    /// Authenticates mim OE using a developer id token, returns the access token from the result.
    private func authenticateMimOE() async -> Result<String, NSError> {
        
        guard let developerIdToken = ConfigManager.fetchConfig(for: .devIdToken) else {
            print("⚠️ Developer id token error")
            return .failure(NSError(domain: "Developer id token error", code: 500))
        }
        
        // Calling mimik Client Library method to get the Access Token for mim OE access
        switch await self.edgeClient.authorizeDeveloper(developerIdToken: developerIdToken) {
        case .success(let authorization):
            
            guard let accessToken = authorization.token?.accessToken else {
                // Authentication unsuccessful, returning failure
                print("⚠️ mim OE access token error")
                return .failure(NSError.init(domain: "mim OE access token error", code: 500))
            }
            
            // Authentication successful, returning success with the Access Token
            return .success(accessToken)
        case .failure(let error):
            print("⚠️ mim OE authentication error", error.localizedDescription)
            // Authentication unsuccessful, returning failure
            return .failure(error)
        }
    }
    
    /// Synchronously shuts down mim OE Runtime and erases its working directory, stored license and startup parameters. As well as any deployed edge microservices and their data. Essentially creating a brand new mimOE instance.
    func resetMimOE() async -> Result<Void, NSError> {
        // Calling mimik Client Library method to shut down and erase mim OE storage
        switch self.edgeClient.resetEdgeEngine() {
        case .success:
            print("✅ mim OE reset successful")
            await processAvailableAIModels()
            return .success(())
        case .failure(let error):
            print("Error", error.localizedDescription)
            print("⚠️ mim OE reset error", error.localizedDescription)
            return .failure(error)
        }
    }
    
    func mimOEInfo() async -> Result<String, NSError> {

        guard case let .success(info) = await self.edgeClient.edgeEngineInfo() else {
            EdgeClient.Log.logError(function: #function, line: #line, items: "No edge engine info", module: .mimikAccess, marker: "⭐️⭐️⭐️")
            return .failure(NSError(domain: "error", code: 500))
        }

        let version = info["version"]
        return .success(version.stringValue)
    }
    
    func removeEverything() async  {
        Task {
            guard case .success = await resetMimOE() else {
                print("Failed to reset mim OE")
                return                            }
            
            UserDefaults.standard.removeObject(forKey: kAIUseCaseDeployment)
            UserDefaults.standard.synchronize()
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            guard case .success = await startupProcedure() else {
                print("failed the mim OE start up procedure")
                return
            }
        }
    }
}
