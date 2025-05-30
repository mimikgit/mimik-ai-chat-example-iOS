//
//  ConfigService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-02-06.
//

import Foundation
import EdgeCore

class ConfigService {

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
    
    public static func fetchConfig(for type: ConfigType, ext: String? = "") -> String? {
        
        guard let filePath = Bundle.main.path(forResource: type.fileName, ofType: ext) else {
            print("⚠️ File not found: \(type.fileName)")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
            
            // Checks for invalid tokens in the file
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
    
    public static func decodeJsonDataFrom<T: Decodable>(file: String, type: T.Type) -> Result<T, NSError> {
        
        guard let filePath = Bundle.main.path(forResource: file, ofType: "json") else {
            print("⚠️ File not found: \(file)")
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
    
    public static func versionBuild() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let versionBuildString = "\(version ?? "") (\(build ?? ""))"
        return versionBuildString
    }
    
    public static func tokenExpiration() -> String {
        guard let token = ConfigService.fetchConfig(for: .devIdToken), let expiresIn = EdgeClient.Authorization.AccessToken.expiresIn(token: token) else {
            return "Invalid Token"
        }
        return expiresIn.formatted()
    }
        
    static func modelPresets() -> [EdgeClient.AI.Model.CreateModelRequest] {
        
        var models: [EdgeClient.AI.Model.CreateModelRequest] = []
        
        for number in 1...5 {
            
            let filename = "config-ai-model\(number)-download"
            
            guard case let .success(decodedModel) = ConfigService.decodeJsonDataFrom(file: filename, type: EdgeClient.AI.Model.CreateModelRequest.self) else {
                continue
            }
            
            if (decodedModel.kind == .vlm || decodedModel.expectedDownloadSize > 2_000_000_000), !ProcessInfo.processInfo.isiOSAppOnMac {
                continue
            }
            
            models.append(decodedModel)
        }
        
        return models
    }
}

extension EdgeClient.AI.Model.CreateModelRequest {
    var shortDescription: String {
        let components = id.split(separator: "/")
        if components.count > 1{
            let partAfterSlash = components[1]
            return String(partAfterSlash)
        } else {
            print("No '/' found in the string")
            return id
        }
    }
}
