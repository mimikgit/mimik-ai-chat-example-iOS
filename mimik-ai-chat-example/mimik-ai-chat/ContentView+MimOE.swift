//
//  ContentView+MimOE.swift
//

import Alamofire
import EdgeCore
import EdgeEngine
import SwiftUI
import SwiftyJSON

extension ContentView {
    
    /// Runs the mimOE startup procedure. Authenticates mimOE using a developer id token, saves the access token from the result. Checks for any available AI models.
    func startupProcedure() async -> Result<Void, NSError> {
        
        guard case .success = await startMimOE() else {
            response = "mimOE startup error"
            return .failure(NSError(domain: "mimOE startup error", code: 500))
        }
        
        guard case let .success(token) = await authenticateMimOE() else {
            response = "mimOE authentication error"
            return .failure(NSError(domain: "mimOE authentication error", code: 500))
        }
        
        mimOEAccessToken = token
        
        print("✅ mimOE access token:", mimOEAccessToken)
        
        if let apiKey = LoadConfig.mimikAIUseApiKey(), let useCase = useCaseDeployment?.useCase, case let .success(models) = await self.edgeClient.availableAIModels(accessToken: mimOEAccessToken, apiKey: apiKey, useCase: useCase), !models.isEmpty {
            await processAvailableAIModels()
            return .success(())
        }
        else {
            print("⚠️ No AI models have been downloaded.")
            menuLabel = ""
            return .success(())
        }
    }
    
    /// Starts mimOE.
    private func startMimOE() async -> Result<Void, NSError> {
        
        guard let edgeLicense = LoadConfig.mimOELicense() else {
            print("⚠️ mimOE license error")
            return .failure(NSError(domain: "mimOE license error", code: 500))
        }

        // Configuring the StartupParameters object with the developer edge license.
        let startupParameters = EdgeClient.StartupParameters(license: edgeLicense, logLevel: .off)

        // Calling mimik Client Library method to starting mimOE asynchronously, waiting for the result.
        switch await self.edgeClient.startEdgeEngine(parameters: startupParameters) {
        case .success:
            print("✅ Starting mimOE successful")
            // Startup successful, returning success.
            return .success(())
        case .failure(let error):
            print("⚠️ Starting mimOE error", error.localizedDescription)
            // Startup unsuccessful, returning failure.
            return .failure(error)
        }
    }
    
    /// Authenticates mimOE using a developer id token, returns the access token from the result.
    private func authenticateMimOE() async -> Result<String, NSError> {
        
        guard let developerIdToken = LoadConfig.devIdToken() else {
            print("⚠️ Developer id token error")
            return .failure(NSError(domain: "Developer id token error", code: 500))
        }
        
        // Calling mimik Client Library method to get the Access Token for mimOE access
        switch await self.edgeClient.authorizeDeveloper(developerIdToken: developerIdToken) {
        case .success(let authorization):
            
            guard let accessToken = authorization.token?.accessToken else {
                // Authentication unsuccessful, returning failure
                print("⚠️ mimOE access token error")
                return .failure(NSError.init(domain: "mimOE access token error", code: 500))
            }
            
            // Authentication successful, returning success with the Access Token
            return .success(accessToken)
        case .failure(let error):
            print("⚠️ mimOE authentication error", error.localizedDescription)
            // Authentication unsuccessful, returning failure
            return .failure(error)
        }
    }
    
    /// Synchronously shuts down mimOE Runtime and erases its working directory, stored license and startup parameters. As well as any deployed edge microservices and their data. Essentially creating a brand new mimOE instance.
    func resetMimOE() async -> Result<Void, NSError> {
        // Calling mimik Client Library method to shut down and erase mimOE storage
        switch self.edgeClient.resetEdgeEngine() {
        case .success:
            print("✅ mimOE reset successful")
            downloadedModels.removeAll()
            Task {
                await processAvailableAIModels()
            }
            return .success(())
        case .failure(let error):
            print("Error", error.localizedDescription)
            print("⚠️ mimOE reset error", error.localizedDescription)
            return .failure(error)
        }
    }
}
