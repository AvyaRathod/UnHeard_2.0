//
//  BucketContentView.swift
//  UnHeard
//
//  Created by Avya Rathod on 28/02/24.
//

import SwiftUI
import AVKit
import Combine

struct DirectoryPlacard: View {
    let directory: String
    
    var backgroundColor: Color {
        Color(
            red: Double.random(in: 0.4...0.8),
            green: Double.random(in: 0.4...0.8),
            blue: Double.random(in: 0.4...0.8),
            opacity: 1.0
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 15)
                .fill(backgroundColor)
                .shadow(radius: 5)
            
            Spacer()
            Text(directory)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding([.bottom, .trailing], 10)
        }
        .frame(width: 160, height: 120)
    }
}

struct Placard: View {
    let word: String
    
    var backgroundColor: Color {
        Color(
            red: Double.random(in: 0.4...0.8),
            green: Double.random(in: 0.4...0.8),
            blue: Double.random(in: 0.4...0.8),
            opacity: 1.0
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 15)
                .fill(backgroundColor)
                .shadow(radius: 5)
            
            Spacer() // Hopefully be able to display a video here
            Text(word)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding([.bottom, .trailing], 10)
        }
        .frame(width: 160, height: 120)
    }
}

struct BucketListView: View {
    @StateObject private var viewModel = BucketViewModel()
    @State private var searchQuery = ""
    @State private var selectedWord: String?
    @State private var isShowingDetail = false
    @State private var showingTypeClassContent: String? = nil
    @State private var videoUrlToShow: String? = nil
    
    private var backButton: some View {
        Group {
            if showingTypeClassContent != nil || !searchQuery.isEmpty {
                Button(action: {
                    showingTypeClassContent = nil
                    searchQuery = ""
                    self.isShowingDetail = false
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            self.isShowingDetail = false
            self.selectedWord = nil
        }) {
            Image(systemName: "xmark")
                .imageScale(.large)
        }
    }
    
    private func generateVideoUrlToShow() {
        if let videoFileName = self.viewModel.videoFilesInDirectories[self.showingTypeClassContent! + "/" + self.selectedWord!] {
            let encodedVideoFileName = videoFileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let videoUrl = "https://storage.googleapis.com/isldictionary/\(encodedVideoFileName)"
            self.videoUrlToShow = videoUrl
        }
    }
    var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var searchResults: [String] {
        if let selectedDirectory = showingTypeClassContent {
            // If a directory is selected, and search query is not empty, filter the second-level directories
            if !searchQuery.isEmpty {
                return viewModel.secondLevelDirectories[selectedDirectory]?.filter {
                    $0.lowercased().contains(searchQuery.lowercased())
                } ?? []
            } else {
                // If search query is empty, display all second-level directories under the selected directory
                return viewModel.secondLevelDirectories[selectedDirectory] ?? []
            }
        } else {
            // If no directory is selected, filter the first-level directories based on the search query
            if searchQuery.isEmpty {
                return viewModel.directories
            } else {
                return viewModel.directories.filter {
                    $0.lowercased().contains(searchQuery.lowercased()) ||
                    (viewModel.secondLevelDirectories[$0]?.contains(where: {
                        $0.lowercased().contains(searchQuery.lowercased())
                    }) ?? false)
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                TextField(showingTypeClassContent != nil ? "Search in \(showingTypeClassContent!)" : "Search", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(searchResults, id: \.self) { directory in
                        if showingTypeClassContent == nil {
                            DirectoryPlacard(directory: directory)
                                .onTapGesture {
                                    showingTypeClassContent = directory
                                    searchQuery = ""
                                }
                        } else {
                            Placard(word: directory)
                                .onTapGesture {
                                    self.selectedWord = directory // This should trigger URL generation
                                    self.generateVideoUrlToShow() // Call the function to generate the URL
                                    self.isShowingDetail = true
                                }
                        }
                    }
                }
            }
            .blur(radius: isShowingDetail ? 20 : 0)
            .navigationBarTitle(showingTypeClassContent ?? "Sign Dictionary", displayMode: .inline)
            .navigationBarItems(leading: isShowingDetail ? nil : backButton,
                                trailing: isShowingDetail ? closeButton : nil)
            .overlay (
                Group{
                    if isShowingDetail{
                        if let videoUrl = videoUrlToShow, let url = URL(string: videoUrl) {
                            VideoOverlay(videoUrl: url, selectedWord: selectedWord ?? "")
                        } else {
                            Text("Error loading video")
                        }
                    }
                }
            )
        }
        .onAppear {
            viewModel.fetchFirstLevelDirectories()
        }
    }
}

struct VideoOverlay: View {
    let videoUrl: URL
    let selectedWord: String
    @State private var player = AVPlayer()
    @State private var playerStatusObserver: AnyCancellable?

    var body: some View {
        VStack {
            Text(selectedWord)
                .font(.title)
                .padding()
            Spacer()
            VideoPlayer(player: player)
                .onAppear {
                    setUpVideoPlayer()
                }
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 9 / 16)
                .cornerRadius(12)
            Spacer()
        }
    }

    private func setUpVideoPlayer() {
        let asset = AVURLAsset(url: videoUrl)
        
        // Preload essential properties
        let keysToLoad = ["playable", "duration"]
        asset.loadValuesAsynchronously(forKeys: keysToLoad) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            if status == .loaded {
                DispatchQueue.main.async {
                    let playerItem = AVPlayerItem(asset: asset)
                    self.player.replaceCurrentItem(with: playerItem)
                    self.player.isMuted = true
                    self.player.play()
                }
            } else {
                // Handle error
                print("Failed to load video asset: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

#Preview {
    BucketListView()
}


//.sheet(isPresented: $isShowingDetail) {
//    if let videoUrl = videoUrlToShow, let url = URL(string: videoUrl) {
//        VideoPlayer(player: AVPlayer(url: url))
//            .onAppear {
//                AVPlayer(url: url).play()
//            }
//    } else {
//        Text("Error loading video")
//    }
//}
