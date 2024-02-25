import SwiftUI

struct QuizView: View {
    @StateObject private var recognizedTextViewModel = RecognizedTextViewModel()
    @StateObject private var cameraState = CameraState()
    @StateObject var modelState = ModelState()
    
    @State private var score: Int = 0
    @State private var currentLetter: String = "A"
    @State private var timeRemaining: Int = 30
    @State private var recognizedSign: String = "A"
    @State private var confidence: Double = 0.0
    
    @State private var isQuizActive = false
    @State private var questionsAnswered: Int = 0
    @State private var showQuizEndSheet: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
    var body: some View {
        ZStack {
            LiveStreamView(recognizedTextViewModel: recognizedTextViewModel, modelState:modelState, cameraState: cameraState)
            
            VStack {
                
                HStack{
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .frame(width: 20, height: 20)
                                .foregroundColor(index < questionsAnswered ? Color.green.opacity(0.5) : Color.black.opacity(0.5))
                        }
                    }
                    .padding()
                    Spacer()
                    Text("Score: \(score) pts")
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(15)
                        .padding(.top, 10)
                        .padding(.trailing, 20)
                }
                
                VStack{
                    Text("Make the sign for:")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding([.top, .leading, .trailing])
                    
                    Text(currentLetter)
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                        .fontWeight(.heavy)
                        .padding([.leading, .bottom, .trailing])
                }
                .background(Color.black.opacity(0.5))
                .cornerRadius(25)
                .frame(minWidth: 0, maxWidth: .infinity)
                
                Spacer()
                
                VStack {
                    Text("Time Left: \(timeRemaining)")
                        .onReceive(timer) { _ in
                            if timeRemaining > 0, isQuizActive, !showQuizEndSheet {
                                timeRemaining -= 1
                            }
                        }
                    
                    HStack(spacing: 38.0) {
                        
                        Button(action: {
                            cameraState.isFrontCamera.toggle()
                        }) {
                            Image(systemName: "camera.rotate")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .padding()
                                .foregroundColor(.white)
                            
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Recognized sign: \(recognizedTextViewModel.latestPrediction)")
                                .font(.title2)
                            Text("confidence: \(Int(recognizedTextViewModel.latestConfidence * 100))%")
                        }
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.black.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            
            if !isQuizActive {
                VStack(spacing: 20) {
                    Text("Welcome to the Quiz!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("When you're ready, press Start to begin.")
                        .foregroundColor(.white)
                    
                    Button("Start Quiz") {
                        startQuiz()
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
                .edgesIgnoringSafeArea(.all)
            }
        }
        .edgesIgnoringSafeArea(.horizontal)
        .onAppear {
            generateRandomLetter()
            timeRemaining = 30
            isQuizActive = false
            modelState.isProcessing = isQuizActive
            score = 0
        }
        .onReceive(recognizedTextViewModel.$latestPrediction) { prediction in
            if timeRemaining > 0, prediction == currentLetter{
                score += 100
                questionsAnswered += 1
                generateRandomLetter()
                timeRemaining = 30
                if questionsAnswered == 3 {
                    showQuizEndSheet = true
                    modelState.isProcessing = false
                }
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining == 0 {
                generateRandomLetter()
                timeRemaining = 30
                questionsAnswered += 1
                if questionsAnswered == 3 {
                    showQuizEndSheet = true
                    modelState.isProcessing = false
                }
            }
        }
        .onChange(of: isQuizActive) { isActive in
            modelState.isProcessing = isActive
        }
        .onDisappear{
            resetQuiz()
        }
        .sheet(isPresented: $showQuizEndSheet) {
            QuizEndView(score: score, retryAction: reStartQuiz)
        }
    }
    
    func startQuiz() {
        isQuizActive = true
        generateRandomLetter()
        modelState.isProcessing = true
        timeRemaining = 30
        score = 0
        questionsAnswered = 0
        showQuizEndSheet = false
    }
    
    func reStartQuiz() {
        isQuizActive = false
        generateRandomLetter()
        modelState.isProcessing = false
        timeRemaining = 30
        score = 0
        questionsAnswered = 0
        showQuizEndSheet = false
    }
    
    func resetQuiz() {
        isQuizActive = false
        score = 0
        timeRemaining = 30
        questionsAnswered = 0
        modelState.isProcessing = false
    }
    
    func generateRandomLetter() {
        let randomIndex = Int.random(in: 0..<alphabet.count)
        currentLetter = String(alphabet[alphabet.index(alphabet.startIndex, offsetBy: randomIndex)])
    }
}

struct QuizEndView: View {
    let score: Int
    var retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Quiz Completed!")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text("Your score: \(score)")
                .font(.title)
                .foregroundColor(.secondary)
            
            if score == 0{
                Text("How about we give this another try")
                    .font(.title)
                    .foregroundColor(.secondary)
            }else if score == 300 {
                Text("Perfect Score!! Keep it up")
                    .font(.title)
                    .foregroundColor(.secondary)
            }else{
                Text("Good efforts, you can do better")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            
            Button(action: retryAction) {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .padding()
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}
