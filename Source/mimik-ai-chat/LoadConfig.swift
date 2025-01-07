//
//  LoadConfig.swift
//

import Foundation
import EdgeCore

struct LoadConfig: Decodable {
    
    static func devIdToken() -> String? {
        
        // Loading the content of Developer-ID-Token file as a String
        guard let file = Bundle.main.path(forResource: "config-developer-id-token", ofType: nil), let token = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("Developer id token error in the config-developer-id-token file")
            return nil
        }
        
        guard !token.contains("DEVELOPER-ID-TOKEN") else {
            fatalError("Enter your own Developer ID Token in the config-developer-id-token file. See: https://console.mimik.com")
        }
        
        return token
    }

    static func mimOELicense() -> String? {
        
        // Loading the content of a file as a String
        guard let file = Bundle.main.path(forResource: "config-developer-mim-OE-license", ofType: nil), let license = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("mim OE (edge) license error in the config-developer-mim-OE-license file")
            return nil
        }
        
        guard !license.contains("REPLACE") else {
            fatalError("Enter your own Developer mim OE (edge) license in the config-developer-mim-OE-license file. See: https://console.mimik.com")
        }
        
        return license
    }
    
    static func mimikAIUseApiKey() -> String? {
        
        // Loading the content of a file as a String
        guard let file = Bundle.main.path(forResource: "config-mimik-ai-use-case-api-key", ofType: nil), let apiKey = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("⚠️ mimik ai use case API key error in the config-mimik-ai-use-case-api-key file")
            return nil
        }
        
        guard !apiKey.contains("REPLACE ALL") else {
            fatalError("Enter your own API key in the config-mimik-ai-use-case-api-key file")
        }
        
        return apiKey
    }
    
    static func aiModelRequest(file: String) -> EdgeClient.AI.Model.CreateModelRequest? {
        
        // Loading the content of a file as a EdgeClient.AI.Model.CreateModelRequest object
        guard let file = Bundle.main.path(forResource: file, ofType: "json") else {
            print("⚠️ AI model request error")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(EdgeClient.AI.Model.CreateModelRequest.self, from: data)
            return decodedData
        } catch {
            print("⚠️ AI model request error", error.localizedDescription)
            return nil
        }
    }
    
    static func mimikAIUseCaseConfigUrl() -> String? {
        
        // Loading the content of a file as a String
        guard let file = Bundle.main.path(forResource: "config-mimik-ai-use-case-url", ofType: nil), let urlString = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("⚠️ mimik ai use case config url error in the config-mimik-ai-use-case-url file")
            return nil
        }
        
        print("✅ mimik ai use case config url:", urlString)
        return urlString
    }
    
    static func versionBuild() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let versionBuildString = "\(version ?? "") (\(build ?? ""))"
        return versionBuildString
    }
    
    static func tokenExpiration() -> String {
        guard let token = LoadConfig.devIdToken(), let expiresIn = EdgeClient.Authorization.AccessToken.expiresIn(token: token) else {
            return "Invalid Token"
        }
        return expiresIn.formatted()
    }
}
