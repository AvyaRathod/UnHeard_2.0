//
//  ImageProcessingView.swift
//  UnHeard
//
//  Created by Avya Rathod on 04/04/24.
//
import Vision
import UIKit

final class ImageProcessingView{
    func process(_ image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else { return }
        let requests = [VNDetectHumanBodyPoseRequest(),
                        VNDetectHumanHandPoseRequest()].compactMap { $0 }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation), options: [:])
        
        do {
            try requestHandler.perform(requests)
        } catch {
            print("Can't make the request due to \(error)")
        }
        
        let resultPointsProviders = requests.compactMap { $0 as? ResultPointsProviding }
        
        let openPointsGroups = resultPointsProviders
            .flatMap { $0.openPointGroups(projectedOnto: image) }
        
        let closedPointsGroups = resultPointsProviders
            .flatMap { $0.closedPointGroups(projectedOnto: image) }
        
        var points: [CGPoint]?
        
        points = resultPointsProviders
            .filter { !($0 is VNDetectHumanBodyPoseRequest) }
            .flatMap { $0.pointsProjected(onto: image) }
        
        let ProcessedImage = image.draw(openPaths: openPointsGroups,
                                            closedPaths: closedPointsGroups,
                                            points: points)
    }
}


extension UIImage {
    func draw(openPaths: [[CGPoint]]? = nil,
              closedPaths: [[CGPoint]]? = nil,
              points: [CGPoint]? = nil,
              pointFillColor: UIColor = .blue,
              pathStrokeColor: UIColor = .green,
              radius: CGFloat = 5,
              lineWidth: CGFloat = 2) -> UIImage? {
        let scale: CGFloat = 0

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the background color to black
        context?.setFillColor(UIColor.black.cgColor)
        context?.fill(CGRect(origin: .zero, size: self.size))
        
        // Redraw the original image on top of the black background
        draw(at: CGPoint.zero)
        
        points?.forEach { point in
            let path = UIBezierPath(arcCenter: point,
                                    radius: radius,
                                    startAngle: 0,
                                    endAngle: CGFloat(Double.pi * 2),
                                    clockwise: true)
            pointFillColor.setFill()
            path.fill()
        }

        openPaths?.forEach { points in
            draw(points: points, isClosed: false, color: pathStrokeColor, lineWidth: lineWidth)
        }

        closedPaths?.forEach { points in
            draw(points: points, isClosed: true, color: pathStrokeColor, lineWidth: lineWidth)
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func draw(points: [CGPoint], isClosed: Bool, color: UIColor, lineWidth: CGFloat) {
        let bezierPath = UIBezierPath()
        bezierPath.drawLinePath(for: points, isClosed: isClosed)
        color.setStroke()
        bezierPath.lineWidth = lineWidth
        bezierPath.stroke()
    }
}


extension UIBezierPath {
    func drawLinePath(for points: [CGPoint], isClosed: Bool) {
        points.enumerated().forEach { [unowned self] iterator in
            let index = iterator.offset
            let point = iterator.element

            let isFirst = index == 0
            let isLast = index == points.count - 1
            
            if isFirst {
                move(to: point)
            } else if isLast {
                addLine(to: point)
                move(to: point)
                
                guard isClosed, let firstItem = points.first else { return }
                addLine(to: firstItem)
            } else {
                addLine(to: point)
                move(to: point)
            }
        }
    }
}

extension UIImage {
    func resizeImage(to newSize: CGSize) -> UIImage? {
        let size = self.size
        let widthRatio  = newSize.width  / size.width
        let heightRatio = newSize.height / size.height
        let newSize = widthRatio > heightRatio ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
                                               : CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}

extension CGPoint {
    func translateFromCoreImageToUIKitCoordinateSpace(using height: CGFloat) -> CGPoint {
        let transform = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0, y: -height);
        
        return self.applying(transform)
    }
}

extension VNRecognizedPoint {
    func location(in image: UIImage) -> CGPoint {
        VNImagePointForNormalizedPoint(location,
                                       Int(image.size.width),
                                       Int(image.size.height))
    }
}

protocol ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint]
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]]
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]]
}

extension VNDetectHumanHandPoseRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] { [] }
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] { [] }
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        point(jointGroups: [[.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip],
                            [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip],
                            [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip],
                            [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip],
                            [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip]],
                            projectedOnto: image)
    }
    
    func point(jointGroups: [[VNHumanHandPoseObservation.JointName]], projectedOnto image: UIImage) -> [[CGPoint]] {
        guard let results = results else { return [] }
        let pointGroups = results.map { result in
            jointGroups
                .compactMap { joints in
                    joints.compactMap { joint in
                        try? result.recognizedPoint(joint)
                    }
                    .filter { $0.confidence > 0.1 }
                    .map { $0.location(in: image) }
                    .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
                }
        }
        
        return pointGroups.flatMap { $0 }
    }
    
    convenience init(maximumHandCount: Int) {
        self.init()
        self.maximumHandCount = maximumHandCount
    }
}

extension VNDetectHumanBodyPoseRequest: ResultPointsProviding {
    func pointsProjected(onto image: UIImage) -> [CGPoint] {
        point(jointGroups: [[.nose, .leftEye, .leftEar, .rightEye, .rightEar]], projectedOnto: image).flatMap { $0 }
    }
    
    func closedPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        point(jointGroups: [[.neck, .leftShoulder, .leftHip, .root, .rightHip, .rightShoulder]], projectedOnto: image)
    }
    
    func openPointGroups(projectedOnto image: UIImage) -> [[CGPoint]] {
        point(jointGroups: [[.leftShoulder, .leftElbow, .leftWrist],
                            [.rightShoulder, .rightElbow, .rightWrist],
                            [.leftHip, .leftKnee, .leftAnkle],
                            [.rightHip, .rightKnee, .rightAnkle]], projectedOnto: image)
    }
    
    func point(jointGroups: [[VNHumanBodyPoseObservation.JointName]], projectedOnto image: UIImage) -> [[CGPoint]] {
        guard let results = results else { return [] }
        let pointGroups = results.map { result in
            jointGroups
                .compactMap { joints in
                    joints.compactMap { joint in
                        try? result.recognizedPoint(joint)
                    }
                    .filter { $0.confidence > 0.1 }
                    .map { $0.location(in: image) }
                    .map { $0.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height) }
                }
        }
        
        return pointGroups.flatMap { $0 }
    }
}
