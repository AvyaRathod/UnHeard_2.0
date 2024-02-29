import SwiftUI
import FirebaseStorage
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
    return true
  }
}

public class StorageManager: ObservableObject {
    let storage = Storage.storage(url:"gs://isldictionary")
}

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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
            BucketListView()
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
