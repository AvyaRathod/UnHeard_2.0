import SwiftUI

struct LiveTyperView: View {
    @StateObject private var recognizedTextViewModel = RecognizedTextViewModel()
    @StateObject var modelState = ModelState()
    @StateObject private var cameraState = CameraState()
    @State private var isShowingModal = false
    
    var body: some View {
        ZStack {
            LiveStreamView(recognizedTextViewModel: recognizedTextViewModel, modelState:modelState, cameraState:cameraState)
            
            VStack {
                Spacer()
                Text(recognizedTextViewModel.recognizedText)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                VStack(spacing: 2) {
                    HStack {
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
                        
                        Spacer()
                        
                        Button(action: {
                            modelState.isProcessing.toggle()
                        }) {
                            Image(systemName: modelState.isProcessing ? "stop.fill" : "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(modelState.isProcessing ? .red : .green)
                                .padding(20)
                        }
                    }
                    .padding(.horizontal, 10.0)
                    .padding(.top,8.0)
                    
                    Text(recognizedTextViewModel.typedText)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .leading)
                        .padding()
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.5))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                )
            }.onTapGesture {
                self.isShowingModal = true
            }
        }
        .edgesIgnoringSafeArea(.top)
        .sheet(isPresented: $isShowingModal) {
            NavigationView{
                VStack(alignment: .leading) {
                    Text("Detected Letter: \(recognizedTextViewModel.recognizedText)")
                        .foregroundStyle(Color.white)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    
                    Text("Generated Text")
                        .foregroundStyle(Color.white)
                        .font(.headline)
                        .padding([.leading, .top])
                    
                    Text(recognizedTextViewModel.typedText)
                        .foregroundStyle(Color.white)
                        .padding([.leading, .bottom, .trailing])
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
                .navigationBarItems(
                    leading: Button(action: {
                        isShowingModal.toggle()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                )
            }
            .presentationBackground(Color.black.opacity(0.9))
                    }
    }
}
