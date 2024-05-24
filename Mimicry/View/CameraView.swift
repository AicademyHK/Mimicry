//
//  CameraView.swift
//  Mimicry
//
//  Created by Muhammad Afif Fadhlurrahman on 21/05/24.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    CameraPreview(session: viewModel.captureSession)
                        .ignoresSafeArea(edges: .all)
                    
                    VStack {
                        Text("Detected Expression: \(viewModel.detectedExpression)")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                        Spacer()
                    }
                    
                    // Add a semi-transparent circle to show the cropping area
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                        .frame(width: 250, height: 250)
                        .position(x: geometry.size.width / 2, y: (geometry.size.height - 135) / 2) // Adjusted position to accommodate the shift of cropping area upwards
                }
                
                VStack {
                    if let expressionImage = viewModel.detectedExpressionImage {
                        VStack {
                            Spacer()
                            ZStack {
                                backgroundColor(for: viewModel.detectedExpression)
                                    .frame(height: 200)
                                    .edgesIgnoringSafeArea(.all)
                                Circle()
                                    .fill(.white)
                                    .frame(width: 150, height: 150)
                                    .padding(10)
                                Image(nsImage: expressionImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .padding()
                            }
                        }
                    } else {
                        Text("No image available for this expression")
                            .padding()
                            .background(Color.gray.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                    }
                }.frame(width: 800, height: 150)
                Spacer()
            }
            Spacer()
        }
        Spacer()
    }
    
    func backgroundColor(for expression: String) -> Color {
        switch expression {
        case "sad":
            return Color.blue
        case "angry":
            return Color.red
        case "happy":
            return Color.yellow
        case "neutral":
            return Color.white
        default:
            return Color.gray
        }
    }
}

struct CameraPreview: NSViewRepresentable {
    var session: AVCaptureSession?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer = previewLayer
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = nsView.layer as? AVCaptureVideoPreviewLayer {
            previewLayer.session = session
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
