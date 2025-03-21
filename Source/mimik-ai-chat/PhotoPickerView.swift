//
//  PhotoPickerView.swift
//  mimik-ai-chat
//
//  Created by rb on 2025-03-18.
//

import SwiftUI

struct PhotoPickerView: View {
    
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var isFileImporterPresented: Bool
    @Binding var isWaiting: Bool

    var body: some View {
        HStack(alignment: .center) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .onTapGesture {
                        showImagePicker = true
                    }
            } else {
                Image(systemName: "photo.badge.plus")
                    .resizable()
                    .frame(width: 82 * 0.7, height: 57 * 0.7)
                    .foregroundStyle(isWaiting ? .gray : .red)
                    .fontWeight(.ultraLight)
                    .onTapGesture {
                        showImagePicker = true
                    }
                Image(systemName: "filemenu.and.cursorarrow")
                    .resizable()
                    .frame(width: 70 * 0.7, height: 63 * 0.7)
                    .foregroundStyle(isWaiting ? .gray : .red)
                    .fontWeight(.ultraLight)
                    .onTapGesture {
                        isFileImporterPresented.toggle()
                    }
            }
        }
        .frame(width: 130, height: 60)
    }
}
