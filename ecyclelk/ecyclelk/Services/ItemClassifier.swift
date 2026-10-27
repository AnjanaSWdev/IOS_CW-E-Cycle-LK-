//
//  ItemClassifier.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import Foundation
import Vision
import CoreML
import ImageIO

/// One guess from the model.
struct ClassificationResult: Equatable, Identifiable {
    let category: ItemCategory
    /// 0 to 1.
    let confidence: Double
    var id: ItemCategory { category }

    var percentText: String { "\(Int((confidence * 100).rounded()))%" }
}

enum ClassifierError: LocalizedError {
    case modelMissing
    case unreadableImage
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .modelMissing:
            return "The scanning model is missing from the app. Add EwasteClassifier.mlmodel to the project."
        case .unreadableImage:
            return "That image could not be read. Try another photo."
        case .failed(let message):
            return "The model could not analyse the photo: \(message)"
        }
    }
}

/// Turns a photo into ranked category guesses. The app uses Vision + Core ML, tests use a fake.
@MainActor
protocol ItemClassifying {
    /// Most likely first. Takes raw image data (JPEG or HEIC) so it can be passed around safely.
    func classify(imageData: Data) async throws -> [ClassificationResult]
}

/// Maps a label from the model to app categories.
enum ClassifierLabels {
    /// If you train with Monitors and Televisions merged into one "displays" class, the app shows both
    /// as choices with the same score, so the person picks which one it is.
    static func categories(for label: String) -> [ItemCategory] {
        if label == "displays" { return [.monitors, .televisions] }
        return ItemCategory(rawValue: label).map { [$0] } ?? []
    }
}

/// Runs the Create ML model on the device. Photos never leave the phone.
struct VisionItemClassifier: ItemClassifying {
    /// File name of the model in the project, without ".mlmodel".
    var modelName = "EwasteClassifier"

    func classify(imageData: Data) async throws -> [ClassificationResult] {
        let predictions = try await Self.predict(imageData: imageData, modelName: modelName)
        return predictions
            .flatMap { prediction in
                ClassifierLabels.categories(for: prediction.identifier).map {
                    ClassificationResult(category: $0, confidence: prediction.confidence)
                }
            }
            .sorted { $0.confidence > $1.confidence }
    }

    /// Plain (name, confidence) pairs so nothing UI-related crosses into the background work.
    private nonisolated static func predict(imageData: Data, modelName: String) async throws
        -> [(identifier: String, confidence: Double)] {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ClassifierError.modelMissing
        }

        let configuration = MLModelConfiguration()
        #if targetEnvironment(simulator)
        // The simulator cannot run Core ML on the GPU or Neural Engine ("Could not create inference context").
        configuration.computeUnits = .cpuOnly
        #endif
        let model = try VNCoreMLModel(for: MLModel(contentsOf: url, configuration: configuration))

        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop
        #if targetEnvironment(simulator)
        if let cpu = MLComputeDevice.allComputeDevices.first(where: { device in
            if case .cpu = device { return true }
            return false
        }) {
            request.setComputeDevice(cpu, for: .main)
        }
        #endif

        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ClassifierError.unreadableImage
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let rawOrientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up

        do {
            try VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:]).perform([request])
        } catch {
            print("Smart scan failed: \(error)")
            throw ClassifierError.failed(error.localizedDescription)
        }

        let observations = request.results as? [VNClassificationObservation] ?? []
        return observations.map { (identifier: $0.identifier, confidence: Double($0.confidence)) }
    }
}
