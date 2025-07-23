//
//  EngineService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-01.
//

import EdgeCore
import EdgeEngine

class EngineService: ObservableObject {
    
    private let kAIUseCaseDeployment = "kAIUseCaseDeployment"
    @Published var mimOEAccessToken: String = ""
    @Published var mimOEVersion: String = ""
    var mimOEClientId: String = ""
    
    // mimik Client Library
    private let _edgeClient = { () -> EdgeClient in
      EdgeClient.setLoggingLevel(module: .edgeCore,   level: .debug, privacy: .publicAccess, marker: "⚠️")
      EdgeClient.setLoggingLevel(module: .edgeEngine, level: .debug, privacy: .publicAccess, marker: "❗️")
      return EdgeClient()
    }()

    // callers who need only the protocol for fetching edge microservices:
    var hybridEdgeClient: any EdgeClient.AI.HybridEdgeClient { _edgeClient }
    // callers who need the full class:
    var edgeClient: EdgeClient { _edgeClient }
    
    var deployedUseCase: EdgeClient.UseCase? {
                
        get {
            guard case let .success(loadedConfig) = ConfigService.decodeJsonDataFrom(file: "mimik-ai-use-case-config", type: EdgeClient.UseCase.self), let loadedVersion = loadedConfig.version else {
                return nil
            }
                        
            if let data = UserDefaults.standard.object(forKey: kAIUseCaseDeployment) as? Data,
               let deployment = try? JSONDecoder().decode(EdgeClient.UseCase.self, from: data), let storedVersion = deployment.version {

                // Checking against the current use case config url, removing stored info if outdated.
                guard loadedVersion == storedVersion else {
                    print("⚠️ Outdated stored mimik ai use case info found, removing.", "\nloadedVersion:", loadedVersion, "\nstoredVersion:", storedVersion)
                    UserDefaults.standard.removeObject(forKey: kAIUseCaseDeployment)
                    UserDefaults.standard.synchronize()
                    return nil
                }
            
                return deployment
            }
            print("⚠️ No stored mimik ai use case deployment found")
            return nil
        }
        
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else {
                return
            }
            
            UserDefaults.standard.set(encoded, forKey: kAIUseCaseDeployment)
            UserDefaults.standard.synchronize()
            
            print("✅ Integrate AI use case success, saved to UserDefaults")
        }
    }
    
    // Runs the mim OE startup procedure. Authenticates mim OE using a developer id token, saves the access token from the result.
    @MainActor
    func startupProcedure() async throws {
        
        try await startMimOE()
        
        guard case let .success(token) = await authenticateMimOE(), case let .success(version) = await mimOEInfo() else {
            throw NSError(domain: "mim OE Authentication", code: 500)
        }
        
        mimOEAccessToken = token
        mimOEVersion = version
        
        print("✅ mim OE access token:", mimOEAccessToken)
        print("✅ mim OE version:", mimOEVersion)
    }
    
    // Resets mim OE storage, removing all user data from mim OE storage, including downloaded AI models.
    func removeEverything() async throws {
        do {
            try await resetMimOE()
            await stateReset()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await startupProcedure()
        }
        catch {
            throw error
        }
    }
    
    // Starts mim OE.
    private func startMimOE() async throws {
        
        guard let edgeLicense = ConfigService.fetchConfig(for: .mimOELicense) else {
            print("⚠️ mim OE license error")
            throw NSError(domain: "mim OE license error", code: 500)
        }

        // Configuring startup parameters with the developer mim OE license.
        // Sets the console logging out for mim OE to OFF
        let startupParameters = EdgeClient.StartupParameters(license: edgeLicense, logLevel: .off)

        // Calls mimik Client Library method to start mim OE asynchronously.
        switch await self.edgeClient.startEdgeEngine(parameters: startupParameters) {
        case .success:
            print("✅ Starting mim OE successful")
        case .failure(let error):
            print("⚠️ Starting mim OE error", error.localizedDescription)
            throw error
        }
    }
    
    // Authenticates mim OE using a developer id token, returns the access token from the result.
    private func authenticateMimOE() async -> Result<String, NSError> {
        
        guard let developerIdToken = ConfigService.fetchConfig(for: .devIdToken) else {
            print("⚠️ Developer id token error")
            return .failure(NSError(domain: "Developer id token error", code: 500))
        }
        
        // Calls mimik Client Library method to get the Access Token for mim OE access
        switch await self.edgeClient.authorizeDeveloper(developerIdToken: developerIdToken) {
        case .success(let authorization):
            
            guard let accessToken = authorization.token?.accessToken else {
                // Authentication unsuccessful, returns a failure
                print("⚠️ mim OE access token error")
                return .failure(NSError.init(domain: "mim OE access token error", code: 500))
            }
            
            mimOEClientId = authorization.token?.clientId() ?? ""
            print("✅ mim OE client id: \(mimOEClientId)")
            
            // Authentication successful, returns the Access Token
            return .success(accessToken)
        case .failure(let error):
            print("⚠️ mim OE authentication error", error.localizedDescription)
            // Authentication unsuccessful, returns a failure
            return .failure(error)
        }
    }
    
    // Synchronously shuts down mim OE and erases its working directory, stored license and startup parameters. As well as any deployed edge microservices and their data. Essentially creating a brand new mim OE instance.
    private func resetMimOE() async throws {
        // Calling mimik Client Library method to shut down and erase mim OE storage
        switch self.edgeClient.resetEdgeEngine() {
        case .success:
            print("✅ mim OE reset successful")
        case .failure(let error):
            print("Error", error.localizedDescription)
            print("⚠️ mim OE reset error", error.localizedDescription)
            throw error
        }
    }
    
    // Returns useful mim OE Runtime information
    private func mimOEInfo() async -> Result<String, NSError> {
        guard case let .success(info) = await self.edgeClient.edgeEngineInfo() else {
            return .failure(NSError(domain: "error", code: 500))
        }

        print("✅ mim OE info", info)
        let version = info["version"]
        return .success(version.stringValue)
    }
    
    @MainActor
    private func stateReset() {
        mimOEVersion = ""
        mimOEAccessToken = ""
        UserDefaults.standard.removeObject(forKey: kAIUseCaseDeployment)
        UserDefaults.standard.synchronize()
        print("⚠️ EngineService state reset")
    }
}
