//
//  LoadConfig.swift
//  AI-Demo
//
//  Created by rb on 2025-02-06.
//

import Foundation
import EdgeCore
import Alamofire
import SwiftyJSON

enum ConfigType: String {
    case milmApiKey = "config-mimik-ai-use-case-api-key"
    case mimOELicense = "config-developer-mim-OE-license"
    case ownerCode = "config-owner-code"
    case devIdToken = "config-developer-id-token"
    case useCaseConfigUrl = "config-use-case-config-url"
    case useCaseConfig = "config-use-case"
    
    var placeholder: String {
        return "<"
    }
    
    var fileName: String {
        return self.rawValue
    }
}

class ConfigManager {

    static func fetchConfig(for type: ConfigType, ext: String? = "") -> String? {
        // Attempt to find the file path
        guard let filePath = Bundle.main.path(forResource: type.fileName, ofType: ext) else {
            print("⚠️ File not found: \(type.fileName)")
            return nil
        }
        
        // Attempt to read the content of the file
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
            
            // Check for invalid tokens in content
            guard !content.contains(type.placeholder) else {
                print("⚠️ Invalid token in file: \(type.fileName)")
                return nil
            }
            
            return content
        } catch {
            print("⚠️ Failed to read file: \(type.fileName)")
            return nil
        }
    }
    
    static func decodeJsonDataFrom<T: Decodable>(file: String, type: T.Type) -> Result<T, NSError> {
        guard let filePath = Bundle.main.path(forResource: file, ofType: "json") else {
            print("⚠️ JSON file not found under", file, type)
            return .failure(NSError(domain: "File error", code: 500))
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(T.self, from: data)
            return .success(decodedData)
        } catch {
            print("⚠️ JSON decoding error", error.localizedDescription)
            return .failure(error as NSError)
        }
    }
    
    static func versionBuild() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let versionBuildString = "\(version ?? "") (\(build ?? ""))"
        return versionBuildString
    }
    
    static func tokenExpiration() -> String {
        guard let token = ConfigManager.fetchConfig(for: .devIdToken), let expiresIn = EdgeClient.Authorization.AccessToken.expiresIn(token: token) else {
            return "Invalid Token"
        }
        return expiresIn.formatted()
    }
}
