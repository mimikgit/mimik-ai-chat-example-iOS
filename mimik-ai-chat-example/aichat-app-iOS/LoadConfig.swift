//
//  LoadConfig.swift
//

import Foundation
import EdgeCore

struct LoadConfig: Decodable {
    
    static func devIdToken() -> String? {
        
        // Loading the content of Developer-ID-Token file as a String
        guard let file = Bundle.main.path(forResource: "Developer-ID-Token", ofType: nil), let token = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("Developer id token error")
            return nil
        }
        
        guard !token.contains("DEVELOPER-ID-TOKEN") else {
            fatalError("Enter your own Developer ID Token in the Developer-ID-Token file. Tutorial: https://devdocs.mimik.com/tutorials/02-index")
        }
        
        return token
    }

    static func mimOELicense() -> String? {
        
        // Loading the content of Developer-mimOE-License file as a String
        guard let file = Bundle.main.path(forResource: "Developer-mimOE-License", ofType: nil), let license = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("mimOE license error")
            return nil
        }
        
        guard !license.contains("DEVELOPER-MIMOE") else {
            fatalError("Enter your own Developer mimOE license in the Developer-mimOE-License file. Tutorial: https://devdocs.mimik.com/tutorials/02-index")
        }
        
        return license
    }
    
    static func aiModelRequest() -> EdgeClient.AI.Model.CreateModelRequest? {
        
        // Loading the content of AI-Model-Request.json file as a EdgeClient.AI.Model.CreateModelRequest object
        guard let file = Bundle.main.path(forResource: "AI-model-request", ofType: "json") else {
            print("⚠️ AI model request error")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(EdgeClient.AI.Model.CreateModelRequest.self, from: data)
            return decodedData
        } catch {
            print("⚠️ AI model request error:", error.localizedDescription)
            return nil
        }
    }
    
    static func mimikAIUseCaseConfigUrl() -> String? {
        
        // Loading the content of Developer-ID-Token file as a String
        guard let file = Bundle.main.path(forResource: "mimik-ai-use-case-config-url", ofType: nil), let urlString = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("⚠️ mimik ai use case config url error")
            return nil
        }
        
        print("✅ mimik ai use case config url:", urlString)
        return urlString
    }
    
    static func mimikAIUseApiKey() -> String? {
        
        // Loading the content of Developer-ID-Token file as a String
        guard let file = Bundle.main.path(forResource: "mimik-ai-use-case-api-key", ofType: nil), let apiKey = try? String(contentsOfFile: file).replacingOccurrences(of: "\n", with: "") else {
            print("⚠️ mimik ai use case API key error")
            return nil
        }
        
        guard !apiKey.contains("REPLACE") else {
            fatalError("Enter your own API key in the mimik-ai-use-case-api-key file")
        }
        
        print("✅ mimik ai use case API key", apiKey)
        return apiKey
    }
}
