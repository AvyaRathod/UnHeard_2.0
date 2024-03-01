//
//  VideoPlayer.swift
//  UnHeard
//
//  Created by Avya Rathod on 01/03/24.
//

import SwiftUI
import AVKit

struct VideoPlayerC: View {
    var body: some View {
        let videoUrl = "https://storage.googleapis.com/isldictionary/Adjectives/Beautiful/Beautiful.MOV"
        
        VideoPlayer(player: AVPlayer(url: URL(string: videoUrl)!))
        
    }
}

#Preview {
    VideoPlayerC()
}
