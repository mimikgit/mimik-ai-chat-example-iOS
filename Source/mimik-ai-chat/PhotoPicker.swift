import Foundation
import SwiftUI
import UIKit
import PhotosUI
import AVFoundation
import QuickLookThumbnailing

struct PhotoPicker: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    
    var pickerResult: PHPickerResult?
    var videoThumbnail: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.isModalInPresentation = false
        picker.modalPresentationCapturesStatusBarAppearance = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        
        var parent: PhotoPicker
        
        init(parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                print("No picker results found.")
                picker.dismiss(animated: true)
                return
            }
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                    }
                    else if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            print("✅ Picker results found: \(result)")
                            self.parent.selectedImage = image
                            self.parent.showImagePicker = false
                        }
                    }
                }
            }
        }
    }
}
