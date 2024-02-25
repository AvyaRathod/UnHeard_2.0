//
//  CropHands.swift
//  UnHeard
//
//  Created by Avya Rathod on 06/02/24.
//

import Vision
import CoreGraphics
import CoreImage

func cropHands(from pixelBuffer: CVPixelBuffer, using observations: [VNHumanHandPoseObservation]) -> CVPixelBuffer? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    var maxX: CGFloat = .zero
    var maxY: CGFloat = .zero
    var minX: CGFloat = CGFloat.greatestFiniteMagnitude
    var minY: CGFloat = CGFloat.greatestFiniteMagnitude

    // Iterate over all points from all hands to find the extreme points
    for observation in observations {
        guard let points = try? observation.recognizedPoints(.all) else { continue }
        let validPoints = points.filter { $0.value.confidence > 0.5 }
        for (_, point) in validPoints {
            let location = CGPoint(x: point.location.x, y: 1 - point.location.y) // Convert Vision point to UIKit coordinate system
            maxX = max(maxX, location.x)
            maxY = max(maxY, location.y)
            minX = min(minX, location.x)
            minY = min(minY, location.y)
        }
    }

    // Check if we have valid points, otherwise return nil
    guard maxX != .zero && maxY != .zero && minX != CGFloat.greatestFiniteMagnitude && minY != CGFloat.greatestFiniteMagnitude else {
        return nil
    }

    // Convert points to a CGRect, expanding the box to be large enough to contain both hands
    let width = maxX - minX
    let height = maxY - minY
    // Expand the bounding box by 50% in each direction to ensure both hands are included
    let expansionFactor: CGFloat = 0.5
    let originX = minX - width * expansionFactor
    let originY = minY - height * expansionFactor
    let size = max(width, height) * (1 + 2 * expansionFactor) // Ensure the box is square and can fit both hands

    // Create a bounding box
    var boundingBox = CGRect(x: originX, y: originY, width: size, height: size)
    boundingBox = boundingBox.standardized
    boundingBox = VNImageRectForNormalizedRect(boundingBox, Int(CVPixelBufferGetWidth(pixelBuffer)), Int(CVPixelBufferGetHeight(pixelBuffer)))

    // Crop the image to the bounding box
    let croppedCIImage = ciImage.cropped(to: boundingBox)

    // Resize the image to 360x360
    let resizedCIImage = croppedCIImage.transformed(by: CGAffineTransform(scaleX: 360 / boundingBox.size.width, y: 360 / boundingBox.size.height))

    let context = CIContext(options: nil)
    var croppedPixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, 360, 360, kCVPixelFormatType_32BGRA, nil, &croppedPixelBuffer)

    guard status == kCVReturnSuccess, let croppedBuffer = croppedPixelBuffer else {
        return nil
    }

    context.render(resizedCIImage, to: croppedBuffer)

    return croppedBuffer
}
