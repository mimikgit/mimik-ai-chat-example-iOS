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
    
    static func fetchConfig(for type: ConfigType, ext: String? = "") -> String? {
        
        guard let filePath = Bundle.main.path(forResource: type.fileName, ofType: ext) else {
            print("⚠️ File not found: \(type.fileName)")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
            
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
    
    static func versionBuild() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let versionBuildString = "\(version ?? "") (\(build ?? ""))"
        return versionBuildString
    }
    
    static func tokenExpiration() -> String {
        guard let token = ConfigService.fetchConfig(for: .devIdToken), let expiresIn = EdgeClient.Authorization.AccessToken.expiresIn(token: token) else {
            return "Invalid Token"
        }
        return expiresIn.formatted()
    }
    
    static func modelPresets() -> [EdgeClient.AI.Model.CreateModelRequest] {
        var models: [EdgeClient.AI.Model.CreateModelRequest] = []
        
        for filename in bundledModelConfigFilenames() {
            guard case let .success(decoded) = ConfigService.decodeJsonDataFrom(
                    file: filename,
                    type: EdgeClient.AI.Model.CreateModelRequest.self)
            else { continue }
            
            if (decoded.kind == .vlm || decoded.expectedDownloadSize > 2_000_000_000),
               !ProcessInfo.processInfo.isiOSAppOnMac {
                continue
            }
            
            models.append(decoded)
        }
        
        return models
    }
    
    private static func extractIndex(from filename: String) -> Int {
        let base = (filename as NSString).deletingPathExtension
        let afterPrefix = base.replacingOccurrences(of: "config-model-", with: "")
        let parts = afterPrefix.split(separator: "-", maxSplits: 1)
        if let idxString = parts.first, let idx = Int(idxString) {
            return idx
        }
        return Int.max
    }
    
    private static func bundledModelConfigFilenames() -> [String] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let allFiles = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath)) ?? []
        
        let configs = allFiles.filter {
            $0.hasPrefix("config-model-") && $0.hasSuffix(".json")
        }
        
        let sorted = configs.sorted {
            extractIndex(from: $0) < extractIndex(from: $1)
        }
        
        return sorted.map { ($0 as NSString).deletingPathExtension }
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
