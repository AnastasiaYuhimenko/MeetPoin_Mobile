//
//  QRCodeGenerator.swift
//  MeetPoint
//

import CoreImage.CIFilterBuiltins
import UIKit

enum QRCodeGenerator {
    private static let ciContext = CIContext()

    static func image(for string: String) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            generate(from: string)
        }.value
    }

    nonisolated static func generate(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = ciContext.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
