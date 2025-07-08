//
//  ModelService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-02.
//

import EdgeCore
import SwiftUI

extension ModelService {
        
    /// Sends a prompt to the AI assistant using the specified service configuration.
    ///
    /// This function updates the application UI to show an in-flight status message,
    /// prepares the prompt variants (managed vs. user-facing), echoes the user's message
    /// into the chat history, and then invokes the AI service.  The response is streamed
    /// chunk by chunk to the UI.  Any errors during streaming are logged and presented
    /// to the user, and UI state is always cleaned up when finished.
    ///
    /// - Parameters:
    ///   - configuration: The `EdgeClient.AI.ServiceConfiguration` containing the
    ///     service identifier and model information to use for this request.
    ///   - prompt: The original prompt text provided by the user.
    ///   - isValidation: A Boolean flag indicating whether this call is for
    ///     validation purposes only (e.g., syntactic or policy checks).
    /// - Throws: An error if the hybrid AI client fails to initiate the prompt
    ///           or if establishing the streaming connection fails.
    @MainActor
    public func assistantPrompt(configuration: EdgeClient.AI.ServiceConfiguration, prompt: String, isValidation: Bool) async throws {
        appState.generalMessage = "Contacting \(configuration.id) with a prompt. Please wait…"

        let (managedPrompt, userChatPost) = preparePrompt(originalPrompt: prompt, configuration: configuration, isValidation: isValidation)

        postUserPrompt(
            message: .init(role: "user", content: userChatPost, modelId: configuration.modelId)
        )

        let client = EdgeClient.AI.HybridClient(configuration: configuration)
        let cancellable = try await client.assistantPrompt(prompt: .init(role: "user", content: managedPrompt))
        appState.activeProtocolStream = cancellable

        defer {
            appState.newResponse    = ""
            appState.activeStream   = nil
            appState.generalMessage = ""
        }

        do {
            for try await chunk in cancellable.stream {
                processUniversal(stream: chunk)
            }
        } catch {
            EdgeClient.Log.logDebug(function: #function, line: #line, items: "Streaming error: \(error)", module: .edgeCore)
            showError(text: "Streaming error: \(error)")
        }
    }

    /// Builds the managed and display prompts based on validation mode.
    ///
    /// - Parameters:
    ///   - originalPrompt: The user’s original prompt text.
    ///   - configuration: The AI service configuration (used for model identifiers in validation).
    ///   - isValidation: Whether to wrap the prompt and context for validation mode.
    /// - Returns: A tuple containing:
    ///   - `managedPrompt`: The prompt text to send to the AI service (wrapped if validating).
    ///   - `userChatPost`: The string to display in the chat history for the user’s action.
    private func preparePrompt(originalPrompt: String, configuration: EdgeClient.AI.ServiceConfiguration, isValidation: Bool) -> (managedPrompt: String, userChatPost: String) {
        
        let contextLines = appState.postedMessages.map { msg in
            if msg.isUserType {
                return "User: \(msg.content ?? "")"
            } else {
                return "Assistant: \(msg.content ?? "")"
            }
        }
        
        if !isValidation {
            let contextString = contextLines.joined(separator: "\n")
            let managed = """
            \(contextString)
            User: \(originalPrompt)
            """
            return (managed, originalPrompt)
        }

        let validationContext = appState.postedMessages.map { msg in
            msg.isUserType ? ["prompt": msg.content ?? ""] : ["assistant": msg.content ?? ""]
        }
        let managed = "Validate alternative AI assistant's response: \(validationContext) to the user's prompt."
        let userPost = "Validate with \(configuration.modelId)"
        return (managed, userPost)
    }
    
    /// Starts an asynchronous streaming conversation with the specified LLM service using vision input.
    ///
    /// This method will:
    /// 1. Update the app state to show a “Contacting…” message.
    /// 2. Wrap the user’s text prompt in a `Message` and post it to the UI history.
    /// 3. Configure default image resizing options (500×500, 50% quality, 100 KB max).
    /// 4. Create a unified service adapter for the given `service`.
    /// 5. Call its vision-enabled streaming API to receive chunks of the AI’s response.
    /// 6. Process each chunk via `processUniversal(stream:)`, and clear out the interim UI state once complete.
    ///
    /// - Warning: Must be called on the main actor, since it mutates `appState`.
    ///
    /// - Parameters:
    ///   - service: The AI service configuration to use (model ID, endpoint, etc.).
    ///   - prompt:  The raw text prompt to send alongside the image.
    ///   - image:   The `UIImage` to include in the vision request.
    /// - Throws: Rethrows any error from `assistantVisionInputStream(prompt:image:resizeImgOptions:)`,
    ///           including network, decoding, or server-side failures.
    @MainActor
    public func assistantVisionPrompt(configuration: EdgeClient.AI.ServiceConfiguration, prompt: String, image: UIImage) async throws {
                
        appState.generalMessage = "Contacting \(configuration.id) with a prompt. Please Wait..."
        
        let userMessage = EdgeClient.AI.Model.Message(role: "user", content: prompt, modelId: configuration.modelId)
        postUserPrompt(message: userMessage)
        let resizeImgOptions = EdgeClient.ImageResizeOptions(size: CGSize.init(width: 500, height: 500), compressionQuality: 0.5, bytesLimit: 100_000)
        
        let client: any EdgeClient.AI.ServiceInterface = EdgeClient.AI.HybridClient(configuration: configuration)
        let cancellable = try await client.assistantVisionPrompt(prompt: userMessage, image: image, resizeImgOptions: resizeImgOptions)
        appState.activeProtocolStream = cancellable

        do {
            for try await chunk in cancellable.stream {
                processUniversal(stream: chunk)
            }
        } catch {
            EdgeClient.Log.logDebug(function: #function, line: #line, items: "Streaming error: \(error)", module: .edgeCore)
            showError(text: "Streaming error: \(error)")
        }

        appState.newResponse = ""
        appState.activeStream = nil
        appState.generalMessage = ""
    }
}
