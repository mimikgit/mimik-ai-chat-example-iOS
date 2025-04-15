//
//  ChatMessagesView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-01-24.
//

import SwiftUI
import EdgeCore

struct ChatMessagesView: View {
    
    @EnvironmentObject private var appState: StateService
    @State private var position = ScrollPosition(edge: .top)
    
    var body: some View {
        
        ScrollViewReader { proxy in
            
            ScrollView {
                
                ForEach(appState.postedMessages.indices, id: \.self) { index in
                    
                    VStack {
                        HStack(spacing: 0) {
                            
                            if let selection = appState.postedMessages[index] as EdgeClient.AI.Model.Message?, selection.isUserType {
                                userMessage(message: selection)
                            }
          
                            if let selection = appState.postedMessages[index] as EdgeClient.AI.Model.Message?, selection.isAiType {
                                aiMessage(message: selection)
                            }
                        }

                        text(message: appState.postedMessages[index])
                    }
                }
            }
            .contentMargins(.top, 20, for: .scrollContent)
            .scrollPosition($position)
            .onChange(of: appState.postedMessages, { oldValue, newValue in
                
                if let lastIndex = appState.postedMessages.indices.last {
                    withAnimation {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            })
        }
    }
    
    private func text(message: EdgeClient.AI.Model.Message) -> some View {
        Text(Date().formattedTodayDate())
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: message.isUserType ? .trailing : .leading)
            .padding(.horizontal, 16)
    }
    
    private func aiMessage(message: EdgeClient.AI.Model.Message) -> some View {
        ZStack(alignment: .bottomLeading) {
            GradientMessageView(message: message.content ?? "", alignment: .leading, foregroundColor: .white, gradientStyle: .blackToBlack)
        }
    }
    
    private func userMessage(message: EdgeClient.AI.Model.Message) -> some View {
        ZStack(alignment: .bottomTrailing) {
            
            VStack {
                if let thumbnail = message.thumbnailBase64?.decodeBase64StringToImage() {
                    HStack {
                        Spacer()
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 50)
                    }
                }

                GradientMessageView(message: message.content ?? "", alignment: .trailing, foregroundColor: .black, gradientStyle: .blueToLightBlue)
            }
        }
    }
}
