////
////  CameraView.swift
////  UnHeard
////
////  Created by Avya Rathod on 04/04/24.
////
//
//import UIKit
//import AVFoundation
//import SwiftUI
//import Vision
//
//final class CameraView: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
//    var captureSession = AVCaptureSession()
//    var previewLayer = AVCaptureVideoPreviewLayer()
//    var cameraPosition: AVCaptureDevice.Position = .front
//    var overlayImageView: UIImageView!
//    
//    var frameQueue = SafeQueue<CGImage>()
//    let semaphore = DispatchSemaphore(value: 0)
//    
//    var lastFrameTimestamp: CMTime?
//    
//    var recognizedTextViewModel: RecognizedTextViewModel
//    @ObservedObject var modelState: ModelState
//    @ObservedObject var cameraState: CameraState
//    
//    private let imageProcessingView = ImageProcessingView()
//    
//    var screenRect:CGRect! = nil
//    
//    var processedImageSequence: MLMultiArray?
//    var frameIndex = 0
//    
//    var frameCounter = 0
//
//    
//    init(recognizedTextViewModel: RecognizedTextViewModel, modelState: ModelState, cameraState: CameraState) {
//        self.recognizedTextViewModel = recognizedTextViewModel
//        self.modelState = modelState
//        self.cameraState = cameraState
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func handlePrediction(request: VNRequest, error: Error?) {
//        guard let results = request.results as? [VNClassificationObservation],
//              let topResult = results.first, modelState.isProcessing else {
//            return
//        }
//        
//        let predictedText = topResult.identifier.uppercased()
//        let confidence = topResult.confidence
//        
//        DispatchQueue.main.async {
//            self.recognizedTextViewModel.updateRecognizedText(newText: predictedText,modelState:self.modelState)
//            self.recognizedTextViewModel.latestPrediction = predictedText
//            self.recognizedTextViewModel.latestConfidence = confidence
//        }
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCamera()
//        setupVideoDataOutput()
//        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
//        
//        // Setup background thread for frame processing
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            while true {
//                self?.semaphore.wait() // Wait for a signal that a new frame is available
//                if let frame = self?.frameQueue.dequeue() {
//                    let uiimage = UIImage(cgImage: frame)
//                    self?.processFrame(image: uiimage)
//                }
//            }
//        }
//        
//        do {
//            processedImageSequence = try MLMultiArray(shape: [1, 40, 224, 224, 3], dataType: .float32)
//        } catch {
//            print("Error initializing MLMultiArray: \(error.localizedDescription)")
//        }
//    }
//
//    func setupCamera() {
//        captureSession = AVCaptureSession()
//        captureSession.sessionPreset = .high
//        guard let camera = getCamera(with: cameraPosition) else { return }
//        do {
//            let input = try AVCaptureDeviceInput(device: camera)
//            if captureSession.canAddInput(input) {
//                captureSession.addInput(input)
//
//                // Attempt to lock the device for configuration
//                try camera.lockForConfiguration()
//
//                // Set the frame rate to 24 FPS
//                let frameDuration = CMTimeMake(value: 1, timescale: Int32(20) )
//                camera.activeVideoMinFrameDuration = frameDuration
//                camera.activeVideoMaxFrameDuration = frameDuration
//
//                // Unlock the device
//                camera.unlockForConfiguration()
//
//                setupPreview()
//            }
//        } catch {
//            print("Error setting device input or configuring frame rate: \(error)")
//        }
//    }
//    
//    func setupPreview() {
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(previewLayer)
//
//        overlayImageView = UIImageView(frame: view.bounds)
//        overlayImageView.contentMode = .scaleAspectFill
//        overlayImageView.isUserInteractionEnabled = false
//        view.addSubview(overlayImageView)
//
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            self?.captureSession.startRunning()
//        }
//    }
//    
//    @objc func orientationChanged() {
//        updatePreviewLayerOrientation()
//    }
//    
//    func updatePreviewLayerOrientation() {
//            if let connection = previewLayer.connection {
//                let orientation = UIDevice.current.orientation
//                let previewLayerConnection: AVCaptureConnection = connection
//
//                if previewLayerConnection.isVideoOrientationSupported {
//                    switch orientation {
//                    case .portrait:
//                        previewLayerConnection.videoOrientation = .portrait
//                    case .landscapeRight:
//                        previewLayerConnection.videoOrientation = .landscapeLeft
//                    case .landscapeLeft:
//                        previewLayerConnection.videoOrientation = .landscapeRight
//                    case .portraitUpsideDown:
//                        previewLayerConnection.videoOrientation = .portraitUpsideDown
//                    default:
//                        previewLayerConnection.videoOrientation = .portrait
//                    }
//                }
//            }
//        }
//    
//    func switchCamera() {
//        captureSession.beginConfiguration()
//        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
//        
//        captureSession.removeInput(currentInput)
//        
//        cameraPosition = cameraState.isFrontCamera ? .front : .back
//        
//        guard let newCamera = getCamera(with: cameraPosition) else {
//            captureSession.commitConfiguration()
//            return
//        }
//        
//        do {
//            let newInput = try AVCaptureDeviceInput(device: newCamera)
//            if captureSession.canAddInput(newInput) {
//                captureSession.addInput(newInput)
//            } else {
//                captureSession.addInput(currentInput)
//            }
//        } catch {
//            print("Error switching cameras: \(error)")
//            captureSession.addInput(currentInput)
//        }
//        
//        captureSession.commitConfiguration()
//        updatePreviewLayerOrientation()
//    }
//    
//    func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
//        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
//    }
//    
//    private func setupVideoDataOutput() {
//        let videoDataOutput = AVCaptureVideoDataOutput()
//        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//        
//        if captureSession.canAddOutput(videoDataOutput) {
//            captureSession.addOutput(videoDataOutput)
//        } else {
//            print("Could not add video data output to the session")
//        }
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        previewLayer.frame = view.bounds
//        overlayImageView.frame = view.bounds
//    }
//    
//    
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        // Increment the frame counter for each captured frame
//        frameCounter += 1
//        
//        // Check if it's the 5th frame
//        if frameCounter % 5 == 0 {
//            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//                return
//            }
//
//            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//            let context = CIContext(options: nil)
//            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
//                return
//            }
//
//            // Enqueue the frame for processing and reset the frame counter
//            frameQueue.enqueue(cgImage)
//            semaphore.signal()
//        }
//        
//        // Reset the counter after the 5th frame has been added
//        if frameCounter >= 5 {
//            frameCounter = 0
//        }
//    }
//
//    func processFrame(image: UIImage) {
//        imageProcessingView.process(image) { [weak self] processedImage in
//            guard let self = self, let processedImage = processedImage else { return }
//            
//            DispatchQueue.global(qos:.default).async {
//                if let resizedImage = processedImage.resizeImage(to: CGSize(width: 224, height: 224)),
//                   let pixelData = resizedImage.normalizedPixelData() {
//                    self.updateMultiArray(with: pixelData)
//                }
//            }
//        }
//    }
//    
//    func updateMultiArray(with pixelData: [Float]) {
//        guard let sequence = processedImageSequence, frameIndex < 40 else { return }
//        
//        let height = 224
//        let width = 224
//        let channels = 3
//        let sequenceLength = 40
//        
//        for y in 0..<height {
//            for x in 0..<width {
//                for c in 0..<channels {
//                    let offset = ((frameIndex * height * width) + (y * width) + x) * channels + c
//                    sequence[offset] = NSNumber(value: pixelData[(y * width + x) * channels + c])
//                }
//            }
//        }
//        
//        frameIndex += 1
//        
//        print("1 frame added")
//        // Check if the sequence is complete and ready for prediction
//        if frameIndex == sequenceLength {
//            // Perform prediction or pass the sequence to the ML model
//            print("40 frames added")
//            frameIndex = 0 // Reset the index if you want to start a new sequence
//        }
//    }
//
//    
//    func startCaptureSession() {
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            guard let self = self, !self.captureSession.isRunning else { return }
//            self.captureSession.startRunning()
//        }
//    }
//
//    func stopCaptureSession() {
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            guard let self = self, self.captureSession.isRunning else { return }
//            self.captureSession.stopRunning()
//        }
//    }
//}
//
//extension UIImage {
//    func normalizedPixelData() -> [Float]? {
//        guard let cgImage = self.cgImage else { return nil }
//        
//        // Defines the color space
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        
//        let width = cgImage.width
//        let height = cgImage.height
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * width
//        let bitsPerComponent = 8
//        
//        var rawData = [UInt8](repeating: 0, count: height * width * bytesPerPixel)
//        
//        guard let context = CGContext(data: &rawData,
//                                      width: width,
//                                      height: height,
//                                      bitsPerComponent: bitsPerComponent,
//                                      bytesPerRow: bytesPerRow,
//                                      space: colorSpace,
//                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
//            return nil
//        }
//        
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//        
//        // Now rawData contains the image data in the RGBA8888 pixel format.
//        var normalizedPixels: [Float] = []
//        
//        for i in 0..<rawData.count {
//            let rawValue = rawData[i]
//            let normalizedValue = Float(rawValue) / 255.0 // Normalize to [0, 1]
//            normalizedPixels.append(normalizedValue)
//        }
//        
//        return normalizedPixels
//    }
//}
//
//
//extension CameraView: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> CameraView {
//        return self
//    }
//    
//    func updateUIViewController(_ uiViewController: CameraView, context: Context) {
//        uiViewController.modelState = modelState
//        if context.coordinator.cameraPosition != self.cameraPosition {
//            uiViewController.switchCamera()
//        }
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject {
//        var parent: CameraView
//        var cameraPosition: AVCaptureDevice.Position
//        
//        init(_ cameraView: CameraView) {
//            self.parent = cameraView
//            self.cameraPosition = cameraView.cameraPosition
//            super.init()
//        }
//    }
//}
//
//struct CameraPreview: UIViewControllerRepresentable {
//    var recognizedTextViewModel: RecognizedTextViewModel
//    @ObservedObject var modelState: ModelState
//    @ObservedObject var cameraState: CameraState
//    
//    func makeUIViewController(context: Context) -> CameraView {
//        let cameraView = CameraView(recognizedTextViewModel: recognizedTextViewModel, modelState: modelState, cameraState: cameraState)
//        cameraState.cameraView = cameraView
//        return cameraView
//    }
//    
//    func updateUIViewController(_ uiViewController: CameraView, context: Context) {
//        uiViewController.switchCamera()
//    }
//}
//
//struct LiveStreamView: View {
//    @StateObject var recognizedTextViewModel = RecognizedTextViewModel()
//    @ObservedObject var modelState: ModelState
//    @ObservedObject var cameraState: CameraState
//    
//    var body: some View {
//        CameraPreview(recognizedTextViewModel: recognizedTextViewModel, modelState:modelState, cameraState:cameraState)
//            .ignoresSafeArea(.all,edges:.top)
//            .onAppear {
//                self.cameraState.cameraView?.startCaptureSession()
//            }
//            .onDisappear {
//                self.cameraState.cameraView?.stopCaptureSession()
//            }
//    }
//}
//
