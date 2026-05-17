//
//  QRScannerView.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - SwiftUI screen

struct QRScannerView: View {

    @Environment(\.dismiss) private var dismiss

    var onScan: (URL) -> Void

    @State private var permissionDenied = false
    @State private var scanError: String?
    @State private var hasScanned = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if permissionDenied {
                permissionDeniedView
            } else {
                QRScannerRepresentable(
                    onCode: handle(code:),
                    onPermissionDenied: { permissionDenied = true },
                    onError: { scanError = $0 }
                )
                .ignoresSafeArea()

                overlay
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Закрыть") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Сканировать QR")
        .navigationBarTitleDisplayMode(.inline)
        .errorToast($scanError)
    }

    // MARK: - Subviews

    private var overlay: some View {
        VStack {
            Spacer()

            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.appYellow, lineWidth: 4)
                .frame(width: 260, height: 260)
                .shadow(color: .black.opacity(0.4), radius: 20)

            Spacer()

            Text("Наведите камеру на QR-код мероприятия")
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)
            Text("Доступ к камере запрещён")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Разрешите доступ в настройках, чтобы сканировать QR-коды.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Открыть настройки")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPurple)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appYellow)
                    )
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func handle(code: String) {
        guard !hasScanned else { return }

        guard let url = parseURL(from: code) else {
            scanError = "QR-код не распознан как ссылка на мероприятие"
            return
        }

        hasScanned = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
        onScan(url)
    }

    private func parseURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else { return nil }
        return url
    }
}

// MARK: - UIViewControllerRepresentable wrapper

private struct QRScannerRepresentable: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    var onPermissionDenied: () -> Void
    var onError: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onCode = onCode
        vc.onPermissionDenied = onPermissionDenied
        vc.onError = onError
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

// MARK: - UIKit camera controller

final class QRScannerViewController: UIViewController {

    var onCode: ((String) -> Void)?
    var onPermissionDenied: (() -> Void)?
    var onError: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let metadataQueue = DispatchQueue(label: "qrscanner.metadata.queue")
    private let sessionQueue = DispatchQueue(label: "qrscanner.session.queue", qos: .userInitiated)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestAccessAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOrientation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    // MARK: - Setup

    private func requestAccessAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionAsync()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configureSessionAsync()
                } else {
                    DispatchQueue.main.async {
                        self?.onPermissionDenied?()
                    }
                }
            }
        case .denied, .restricted:
            onPermissionDenied?()
        @unknown default:
            onPermissionDenied?()
        }
    }

    private func configureSessionAsync() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async { [weak self] in
                self?.onError?("Камера недоступна")
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            session.beginConfiguration()
            session.sessionPreset = .high

            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    self?.onError?("Не удалось получить доступ к камере")
                }
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    self?.onError?("Не удалось настроить распознавание QR")
                }
                return
            }

            session.commitConfiguration()

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let preview = AVCaptureVideoPreviewLayer(session: self.session)
                preview.videoGravity = .resizeAspectFill
                preview.frame = self.view.bounds
                self.view.layer.insertSublayer(preview, at: 0)
                self.previewLayer = preview
                self.updateOrientation()
                self.startSession()
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onError?("Не удалось запустить камеру")
            }
        }
    }

    private func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func updateOrientation() {
        guard let connection = previewLayer?.connection else { return }
        let interfaceOrientation = view.window?.windowScene?.interfaceOrientation ?? .portrait
        let angle: CGFloat
        switch interfaceOrientation {
        case .portrait: angle = 90
        case .portraitUpsideDown: angle = 270
        case .landscapeLeft: angle = 180
        case .landscapeRight: angle = 0
        default: angle = 90
        }
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }
}

// MARK: - Metadata output delegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            object.type == .qr,
            let value = object.stringValue,
            !value.isEmpty
        else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.stopSession()
            self.onCode?(value)
        }
    }
}
