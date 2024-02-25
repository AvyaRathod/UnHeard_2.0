import SwiftUI

class CameraState: ObservableObject {
    var cameraView: CameraView?
    @Published var isFrontCamera: Bool = true
}

class ModelState: ObservableObject{
    @Published var isProcessing: Bool = false
}

@main
struct UnHeardApp: App {
    @StateObject var cameraState = CameraState()
    @StateObject var modelState = ModelState()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(cameraState)
                .environmentObject(modelState)
                .preferredColorScheme(.dark)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = "Live Typer"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AlphabetDictionaryView()
                .tabItem {
                    Label("Dictionary", systemImage: "book")
                }
                .tag("Dictionary")
            
            LiveTyperView()
                .tabItem {
                    Label("Live Typer", systemImage: "keyboard")
                }
                .tag("Live Typer")
            
            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.circle")
                }
                .tag("Quiz")
        }
    }
}
