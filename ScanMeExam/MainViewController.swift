//
//  MainViewController.swift
//  ScanMeExam
//
//  Created by Bryan Vivo on 4/27/22.
//

import UIKit
import MobileCoreServices
import TesseractOCR

class MainViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var scannedTextContainerLabel: UILabel!
    @IBOutlet weak var resultsContainerLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
        // Do any additional setup after loading the view.
    }

    private func setupTheme() {
    #if RED_CAMERA || RED_LIBRARY
        self.view.backgroundColor = .red
    #elseif GREEN_CAMERA || GREEN_LIBRARY
        self.view.backgroundColor = .green
    #endif
    }
    @IBAction func addInput() {
        self.activityIndicator.startAnimating()
        let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Image", message: nil, preferredStyle: .actionSheet)

        #if !RED_LIBRARY && !GREEN_LIBRARY
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
          let cameraButton = UIAlertAction(title: "Take Photo", style: .default) { (alert) -> Void in
              self.openImagePicker(source: .camera)
          }
          imagePickerActionSheet.addAction(cameraButton)
        }
        #endif
        
        #if !RED_CAMERA && !GREEN_CAMERA
        let libraryButton = UIAlertAction(title: "Choose Existing", style: .default) { (alert) -> Void in
            self.openImagePicker(source: .photoLibrary)
        }
        imagePickerActionSheet.addAction(libraryButton)
        #endif
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { (alert) -> Void in
            self.activityIndicator.stopAnimating()
        }
        imagePickerActionSheet.addAction(cancelButton)

        present(imagePickerActionSheet, animated: true)

    }
    
    private func openImagePicker(source: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source
        imagePicker.mediaTypes = [kUTTypeImage as String]
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func performImageRecognition(_ image: UIImage) {
        if let tesseract = G8Tesseract(language: "eng") {
            tesseract.engineMode = .tesseractCubeCombined
            tesseract.pageSegmentationMode = .auto
            tesseract.setVariableValue("0123456789+-*/", forKey: "tessedit_char_whitelist")
            let scaledImage = image.scaledImage(1000) ?? image
            tesseract.image = scaledImage
            tesseract.recognize()
            scannedTextContainerLabel.text = "Input: \(tesseract.recognizedText ?? "Error")"
            let expression: NSExpression = NSExpression(format: tesseract.recognizedText ?? "")
            if let result = expression.expressionValue(with: nil, context: nil) as? Int {
                resultsContainerLabel.text = "Result: \(result)"
            }
        }
    }
}


extension MainViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.activityIndicator.stopAnimating()
        guard let selectedPhoto =
          info[.originalImage] as? UIImage else {
            dismiss(animated: true)
            return
        }
 
        dismiss(animated: true) {
          self.performImageRecognition(selectedPhoto)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.activityIndicator.stopAnimating()
    }
}

extension UIImage {
  func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)
    if size.width > size.height {
      scaledSize.height = size.height / size.width * scaledSize.width
    } else {
      scaledSize.width = size.width / size.height * scaledSize.height
    }
    UIGraphicsBeginImageContext(scaledSize)
    draw(in: CGRect(origin: .zero, size: scaledSize))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return scaledImage
  }
}
