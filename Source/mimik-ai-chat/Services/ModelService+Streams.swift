//
//  ModelService.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-02.
//

import EdgeCore
import SwiftUI

extension ModelService {
    
    /// Posts a user message to the app state, optionally with a resized image.
    ///
    /// If an image and resize options are provided, the image is resized and encoded as Base64,
    /// then added to the message. Otherwise, the message is posted as-is.
    ///
    /// - Parameters:
    ///   - message: The user message to post.
    ///   - image: Optional image to include.
    ///   - resizeImgOptions: Optional resizing and compression settings.
    internal func postUserPrompt(message: EdgeClient.AI.Model.Message, image: UIImage? = nil, resizeImgOptions: EdgeClient.ImageResizeOptions? = nil) {
        
        if let image = image, let resizeImgOptions = resizeImgOptions, let resizedImage = image.resizeImage(targetSize: resizeImgOptions.size, bytesLimit: resizeImgOptions.bytesLimit, compressionQuality: resizeImgOptions.compressionQuality), let imageBase64String = resizedImage.base64FromJpeg(compressionQuality: 0.5) {
            let newMessageWithImage = EdgeClient.AI.Model.Message(role: message.role, content: message.content, thumbnailBase64: imageBase64String, modelId: message.modelId)
            appState.postedMessages.append(newMessageWithImage)
        }
        else {
            appState.postedMessages.append(message)
        }
    }

    /// Updates the posted messages array with an incoming AI stream chunk.
    ///
    /// If the last message in `appState.postedMessages` was sent by the user,
    /// this method appends the new assistant message. If the last message was
    /// already from the assistant, it merges the incoming chunk’s text into
    /// the existing assistant message. Invalid or unsupported messages are
    /// silently ignored (with a warning logged for unexpected sequences).
    ///
    /// - Parameter message: A partial or complete `Message` from the assistant.
    ///                      Must have a non‐nil `role` and non‐empty `content`.
    /// - Note: Mutates `appState.postedMessages`, so should be called on the main actor
    ///         if used in a UI context.
    internal func ongoingStreamResponse(message: EdgeClient.AI.Model.Message) {
        
        // Ensure we have a role, some content, and at least one existing message
        guard let role = message.role, let content = message.content, let previousMessage = appState.postedMessages.last else {
            return
        }
        
        // Decide whether to append a new assistant message or merge into the last one
        if previousMessage.isUserType {
            
            // Last message was from the user: start a new assistant message
            appState.postedMessages.append(message)
            
        } else if previousMessage.isAiType {
            
            // Last message was from the assistant: merge content into it
            let existingContent = previousMessage.content ?? ""
            let mergedContent = existingContent + content
            
            let mergedMessage = EdgeClient.AI.Model.Message(
                role: role,
                content: mergedContent,
                thumbnailBase64: message.thumbnailBase64,
                modelId: message.modelId
            )
            
            // Replace the last message with the merged one
            appState.postedMessages[appState.postedMessages.count - 1] = mergedMessage
            
        } else {
            // Unexpected case: neither user nor assistant
            print("⚠️ Unsupported message sequence: lastMessage=\(previousMessage)")
        }
    }
    
    /// Processes a single chunk of streaming AI completion and updates UI state and token usage.
    ///
    /// This method handles both intermediate and final chunks from the AI service:
    /// 1. **Finalization**
    ///    - When `stream.finished()` is `true`, it records the usage metrics for the model
    ///      in `appState.tokenUsage` and emits an empty assistant message to close out the UI stream.
    /// 2. **Intermediate chunks**
    ///    - Attempts to extract a content `Message` and its text from the `stream`.
    ///    - Filters out control/status messages whose text contains any of:
    ///      `"[DONE]"`, `"Model loaded successfully"`, `"<|loading_model|>"`,
    ///      `"Loading the model"`, or `"<|processing_prompt|>"`.
    ///    - For valid content, calls `ongoingStreamResponse(message:)` to emit the chunk,
    ///      and appends the text to `appState.newResponse`.
    ///
    /// - Parameter stream: The `CompletionResponse` from the AI, containing optional content,
    ///                     usage metrics, and a `finished()` flag indicating stream completion.
    /// - Note: Mutates `appState`, so should be invoked on the main actor if used in UI contexts.
    func processUniversal(stream: EdgeClient.AI.Model.CompletionResponse) {
        
        if let modelId = stream.model, stream.finished() {
            return handleEndOfStream(stream: stream, modelId: modelId)
        }

        guard let message = stream.contentMessage(), let contentText = stream.contentText() else {
            return
        }

        let skipSubstrings = [
            "[DONE]",
            "Model loaded successfully",
            "<|loading_model|>",
            "Loading the model",
            "<|processing_prompt|>"
        ]
        
        guard !skipSubstrings.contains(where: contentText.contains) else {
            return
        }

        if let modelId = stream.model, stream.finished() {
            let usage = EdgeClient.AI.Model.Usage(promptTokens: stream.usage?.promptTokens, completionTokens: stream.usage?.completionTokens, totalTokens: stream.usage?.totalTokens, tokenPerSecond: stream.usage?.tokenPerSecond)
            appState.tokenUsage[modelId] = usage
        }

        ongoingStreamResponse(message: message)
        appState.newResponse += contentText
    }
  
    /// Handles the final chunk of an AI streaming response by recording usage metrics
    /// and emitting the last assistant message (or a placeholder) to the UI.
    ///
    /// This method will:
    /// 1. Extract and store token usage from the provided `CompletionResponse`.
    /// 2. Attempt to pull out the final assistant message and its text.
    /// 3. If no content is present, emit an empty assistant message to close out the stream.
    /// 4. Append the final text (which may be empty) to `appState.newResponse`.
    ///
    /// - Parameters:
    ///   - stream: The `CompletionResponse` containing optional final content and usage data.
    ///   - modelId: The identifier for the model whose usage metrics should be recorded.
    /// - Note: Mutates `appState`, so should be invoked on the main actor in UI contexts.
    internal func handleEndOfStream(stream: EdgeClient.AI.Model.CompletionResponse, modelId: String) {
        
        // Record token usage for the completed stream
        let usage = EdgeClient.AI.Model.Usage(promptTokens: stream.usage?.promptTokens, completionTokens: stream.usage?.completionTokens, totalTokens: stream.usage?.totalTokens, tokenPerSecond: stream.usage?.tokenPerSecond)
        appState.tokenUsage[modelId] = usage

        // Determine the final assistant message and associated text
        let (finalMessage, finalText): (EdgeClient.AI.Model.Message, String) = {
            if let contentMessage = stream.contentMessage(), let text = stream.contentText() {
                return (contentMessage, text)
            } else {
                // Fallback: emit an empty assistant message to signal end of stream
                let emptyMsg = EdgeClient.AI.Model.Message(role: "assistant", content: "", thumbnailBase64: nil, modelId: modelId)
                return (emptyMsg, "")
            }
        }()

        // Emit the message and append its text to the ongoing response buffer
        ongoingStreamResponse(message: finalMessage)
        appState.newResponse += finalText
    }
}
