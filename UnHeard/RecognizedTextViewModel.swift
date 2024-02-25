import Foundation

class RecognizedTextViewModel: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var typedText: String = ""
    @Published var latestPrediction: String = ""
    @Published var latestConfidence: Float = 0
    
    private var lastRecognizedText: String = ""
    private var consecutiveCount: Int = 0
    
    func updateRecognizedText(newText: String, modelState: ModelState) {
        guard modelState.isProcessing else { return }
        
        if newText == lastRecognizedText {
            consecutiveCount += 1
        } else {
            consecutiveCount = 1
            lastRecognizedText = newText
        }
        
        DispatchQueue.main.async {
            self.recognizedText = newText
        }
        
        if consecutiveCount >= 5 {
            appendToTypedText(text: newText)
            consecutiveCount = 0
        }
    }
    
    private func appendToTypedText(text: String) {
        DispatchQueue.main.async {
            self.typedText += text + " "
        }
    }
}
