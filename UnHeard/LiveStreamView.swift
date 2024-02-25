import UIKit
import AVFoundation
import SwiftUI
import Vision

final class CameraView: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession = AVCaptureSession()
    var previewLayer = AVCaptureVideoPreviewLayer()
    var cameraPosition: AVCaptureDevice.Position = .front
    
    var recognizedTextViewModel: RecognizedTextViewModel
    @ObservedObject var modelState: ModelState
    @ObservedObject var cameraState: CameraState
    
    var screenRect:CGRect! = nil
    
    private var handPoseRequest: VNDetectHumanHandPoseRequest!
    private var predictionModel: VNCoreMLModel!
    private var predictionRequest: VNCoreMLRequest!
    
    init(recognizedTextViewModel: RecognizedTextViewModel, modelState: ModelState, cameraState: CameraState) {
        self.recognizedTextViewModel = recognizedTextViewModel
        self.modelState = modelState
        self.cameraState = cameraState
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCoreMLModel() {
        do {
            predictionModel = try VNCoreMLModel(for: AlphabetsImageClassifier().model)
            predictionRequest = VNCoreMLRequest(model: predictionModel, completionHandler: handlePrediction)
            predictionRequest.imageCropAndScaleOption = .scaleFill
        } catch {
            fatalError("Failed to load Core ML model: \(error)")
        }
    }
    
    private func handlePrediction(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first, modelState.isProcessing else {
            return
        }
        
        let predictedText = topResult.identifier.uppercased()
        let confidence = topResult.confidence
        
        DispatchQueue.main.async {
            self.recognizedTextViewModel.updateRecognizedText(newText: predictedText,modelState:self.modelState)
            self.recognizedTextViewModel.latestPrediction = predictedText
            self.recognizedTextViewModel.latestConfidence = confidence
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupVideoDataOutput()
        setupCoreMLModel()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        guard let camera = getCamera(with: cameraPosition) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                setupPreview()
            }
        } catch {
            print("Error setting device input: \(error)")
        }
    }
    
    func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        updatePreviewLayerOrientation()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    @objc func orientationChanged() {
        updatePreviewLayerOrientation()
    }
    
    func updatePreviewLayerOrientation() {
        if let connection = previewLayer.connection {
            let orientation = UIDevice.current.orientation
            let previewLayerConnection: AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                switch orientation {
                case .portrait:
                    previewLayerConnection.videoOrientation = .portrait
                case .landscapeRight:
                    previewLayerConnection.videoOrientation = .landscapeLeft
                case .landscapeLeft:
                    previewLayerConnection.videoOrientation = .landscapeRight
                case .portraitUpsideDown:
                    previewLayerConnection.videoOrientation = .portraitUpsideDown
                default:
                    previewLayerConnection.videoOrientation = .portrait
                }
            }
        }
    }
    
    func switchCamera() {
        captureSession.beginConfiguration()
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        captureSession.removeInput(currentInput)
        
        cameraPosition = cameraState.isFrontCamera ? .front : .back
        
        guard let newCamera = getCamera(with: cameraPosition) else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            } else {
                captureSession.addInput(currentInput)
            }
        } catch {
            print("Error switching cameras: \(error)")
            captureSession.addInput(currentInput)
        }
        
        captureSession.commitConfiguration()
        updatePreviewLayerOrientation()
    }
    
    func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
    }
    
    private func setupVideoDataOutput() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        } else {
            print("Could not add video data output to the session")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.processFrame(sampleBuffer: sampleBuffer)
        }
    }
    
    func processFrame(sampleBuffer: CMSampleBuffer) {
        guard modelState.isProcessing,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard let predictionRequest = self.predictionRequest else {
            print("Prediction request is not initialized.")
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([predictionRequest])
        } catch {
            print("Failed to perform prediction request: \(error)")
        }
    }
    
    func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    func stopCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
}

extension CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraView {
        return self
    }
    
    func updateUIViewController(_ uiViewController: CameraView, context: Context) {
        uiViewController.modelState = modelState
        if context.coordinator.cameraPosition != self.cameraPosition {
            uiViewController.switchCamera()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CameraView
        var cameraPosition: AVCaptureDevice.Position
        
        init(_ cameraView: CameraView) {
            self.parent = cameraView
            self.cameraPosition = cameraView.cameraPosition
            super.init()
        }
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    var recognizedTextViewModel: RecognizedTextViewModel
    @ObservedObject var modelState: ModelState
    @ObservedObject var cameraState: CameraState
    
    func makeUIViewController(context: Context) -> CameraView {
        let cameraView = CameraView(recognizedTextViewModel: recognizedTextViewModel, modelState: modelState, cameraState: cameraState)
        cameraState.cameraView = cameraView
        return cameraView
    }
    
    func updateUIViewController(_ uiViewController: CameraView, context: Context) {
        uiViewController.switchCamera()
    }
}

struct LiveStreamView: View {
    @StateObject var recognizedTextViewModel = RecognizedTextViewModel()
    @ObservedObject var modelState: ModelState
    @ObservedObject var cameraState: CameraState
    
    var body: some View {
        CameraPreview(recognizedTextViewModel: recognizedTextViewModel, modelState:modelState, cameraState:cameraState)
            .ignoresSafeArea(.all,edges:.top)
            .onAppear {
                self.cameraState.cameraView?.startCaptureSession()
            }
            .onDisappear {
                self.cameraState.cameraView?.stopCaptureSession()
            }
    }
}
