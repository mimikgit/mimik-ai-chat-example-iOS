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
        
        // Loading the content of Developer-mimOE-License file as a String
        guard let file = Bundle.main.path(forResource: "config-developer-mimOE-license", ofType: nil), let license = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("mimOE (Edge) license error in the config-developer-mimOE-license file")
            return nil
        }
        
        guard !license.contains("REPLACE") else {
            fatalError("Enter your own Developer mimOE (Edge) license in the config-developer-mimOE-license file. See: https://console.mimik.com")
        }
        
        return license
    }
    
    static func mimikAIUseApiKey() -> String? {
        
        // Loading the content of Developer-ID-Token file as a String
        guard let file = Bundle.main.path(forResource: "config-mimik-ai-use-case-api-key", ofType: nil), let apiKey = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("⚠️ mimik ai use case API key error in the config-mimik-ai-use-case-api-key file")
            return nil
        }
        
        guard !apiKey.contains("REPLACE ALL") else {
            fatalError("Enter your own API key in the config-mimik-ai-use-case-api-key file")
        }
        
        print("✅ mimik ai use case API key")
        return apiKey
    }
    
    static func aiModelRequest() -> EdgeClient.AI.Model.CreateModelRequest? {
        
        // Loading the content of AI-Model-Request.json file as a EdgeClient.AI.Model.CreateModelRequest object
        guard let file = Bundle.main.path(forResource: "config-ai-model-download", ofType: "json") else {
            print("⚠️ AI model request error in the config-ai-model-download file")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(EdgeClient.AI.Model.CreateModelRequest.self, from: data)
            return decodedData
        } catch {
            print("⚠️ AI model request error in the config-ai-model-download file:", error.localizedDescription)
            return nil
        }
    }
    
    static func mimikAIUseCaseConfigUrl() -> String? {
        
        // Loading the content of Developer-ID-Token file as a String
        guard let file = Bundle.main.path(forResource: "config-mimik-ai-use-case-url", ofType: nil), let urlString = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("⚠️ mimik ai use case config url error in the config-mimik-ai-use-case-url file")
            return nil
        }
        
        print("✅ mimik ai use case config url:", urlString)
        return urlString
    }
}
