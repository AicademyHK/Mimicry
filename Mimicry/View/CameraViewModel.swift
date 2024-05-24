//
//  CameraViewModel.swift
//  Mimicry
//
//  Created by Muhammad Afif Fadhlurrahman on 21/05/24.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedExpression: String = "Unknown"
    @Published var detectedExpressionImage: NSImage? // Properti baru untuk menyimpan gambar
    
    var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var request: VNCoreMLRequest?
    
    override init() {
        super.init()
        setupModel()
        setupCaptureSession()
    }
    
    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            let model = try VNCoreMLModel(for: MimicryClassifier_4(configuration: config).model) // Change the model here
            request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.handleDetection(request: request, error: error)
            }
            request?.imageCropAndScaleOption = .centerCrop
        } catch {
            fatalError("Failed to load model: \(error)")
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        // Setup input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice), captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        // Setup output
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        captureSession.addOutput(videoOutput)
        
        captureSession.startRunning()
    }
    
    private func handleDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("Error in VNCoreMLRequest: \(error.localizedDescription)")
            return
        }
        
        guard let results = request.results as? [VNClassificationObservation] else { return }
        if let topResult = results.first, topResult.confidence > 0.9 {
            DispatchQueue.main.async { [weak self] in
                self?.detectedExpression = topResult.identifier
                self?.detectedExpressionImage = self?.image(for: topResult.identifier) // Update gambar berdasarkan hasil deteksi
            }
        }
    }
    
    private func image(for expression: String) -> NSImage? {
        switch expression {
        case "sad":
            return NSImage(named: "sad")
        case "angry":
            return NSImage(named: "angry")
        case "happy":
            return NSImage(named: "happy")
        case "neutral":
            return NSImage(named: "neutral")
        default:
            return nil
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraData]
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cropRect = CGRect(x: (ciImage.extent.width - 200) / 2, y: ((ciImage.extent.height - 200) / 2) - 135, width: 250, height: 250) // Crop the center part of the frame with 50 pixels shift on y-axis
        let croppedImage = ciImage.cropped(to: cropRect)
        
        let handler = VNImageRequestHandler(ciImage: croppedImage, options: requestOptions)
        do {
            try handler.perform([request!])
        } catch {
            print("Failed to perform request: \(error)")
        }
    }
}

