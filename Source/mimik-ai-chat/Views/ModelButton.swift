//
//  ModelButton.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-04-07.
//

import SwiftUI
import EdgeCore

struct ModelButton: View {
    
    @EnvironmentObject var appState: AppState
    
    var buttonText: String
    var backgroundColor: Color
    var foregroundColor: Color
    var fontSize: CGFloat
    var maxWidth: CGFloat
    var maxHeight: CGFloat
    var model: EdgeClient.AI.Model.CreateModelRequest?
    var action: () -> Void

    var body: some View {
        ZStack {

            Button(action: action) {
                
                HStack {
                    if model != nil {
                        Spacer()
                    }
                    
                    Text(buttonText)
                        .foregroundColor(foregroundColor)
                        .font(.system(size: fontSize, weight: .semibold))
                    
                    if let model = model {
                        Spacer()
                        if appState.alreadyDownloadedModel(id: model.id) {
                            MetallicText(text: "", fontSize: 15, color: .gold, icon: "checkmark.circle.fill", iconPosition: .after)
                        }
                        
                        VStack(alignment: .trailing) {
                            HStack {
                                ColourText(text: model.kind?.rawValue ?? "", fontSize: DeviceType.isTablet ? 10 : 13, color: model.kind == .vlm ? .gold : foregroundColor)
                            }
                            HStack {
                                ColourText(text: model.chatTemplateHint?.rawValue ?? "", fontSize: DeviceType.isTablet ? 10 : 13, color: foregroundColor)
                            }
                            HStack {
                                ColourText(text: AddModelView.ModifiedModel.readableFileSize(model.expectedDownloadSize) , fontSize: DeviceType.isTablet ? 10 : 13, color: foregroundColor)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                .background(backgroundColor)
                .cornerRadius(12)
            }
        }
    }
}
