//
//  File.swift
//  
//
//  Created by Avya Rathod on 02/02/24.
//

import UIKit
import AVFoundation
import Vision

// This function combines frame extraction with pose extraction
func extractPosesFromVideo(url: URL, frameInterval: TimeInterval, completion: @escaping (PoseExtractor) -> Void) {
    let videoFrameExtractor = VideoFrameExtractor()
    let poseExtractor = PoseExtractor()
    
    // Extract frames from the video
    videoFrameExtractor.extractFrames(from: url, interval: frameInterval)
    print("Extracted \(videoFrameExtractor.frames.count) frames from the video.")
    
    // Extract pose information from the frames using the PoseExtractor
    poseExtractor.extractPoses(from: videoFrameExtractor.frames){
        print("completed extracting poses")
    }
}

func testPoseExtractor(image: UIImage) {
    let poseExtractor = PoseExtractor()

    // Extract poses from the single image
    poseExtractor.extractPoses(from: [image]) {
        // After pose extraction is complete, print the results
        print("Body Poses detected: \(poseExtractor.bodyPoses.count)")
        print("Hand Poses detected: \(poseExtractor.handPoses.count)")
        print("Face Landmarks detected: \(poseExtractor.faceLandmarks.count)")

        // If you want to print detailed information about the first body pose as an example
        if let firstBodyPose = poseExtractor.bodyPoses.first {
            do {
                let recognizedPoints = try firstBodyPose.recognizedPoints(forGroupKey: .all)
                let highConfidencePoints = recognizedPoints.filter { $0.value.confidence > 0.5 }
                print("High confidence body points in the first pose: \(highConfidencePoints.count)")
            } catch {
                print("Error retrieving points from body pose observation: \(error)")
            }
        }
    }
}
