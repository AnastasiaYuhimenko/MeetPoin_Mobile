//
//  QRCodeImageView.swift
//  MeetPoint
//

import SwiftUI

struct QRCodeImageView: View {
    let content: String
    var size: CGFloat = 200

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
        .task(id: content) {
            image = nil
            let generated = await QRCodeGenerator.image(for: content)
            guard !Task.isCancelled else { return }
            image = generated
        }
    }
}
