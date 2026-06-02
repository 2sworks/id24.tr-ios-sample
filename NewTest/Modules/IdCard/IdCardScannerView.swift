//
//  IdCardScannerView.swift
//  NewTest
//
//  VisionKit (VNDocumentCameraViewController) tabanlı belge tarayıcı.
//  OpenScanner projesindeki DocumentCameraWrapper yaklaşımı adapte edilmiştir.
//  Coordinator push ile açılır; tarama bitince callback çağrılıp pop yapılır.
//

import SwiftUI
import VisionKit

// MARK: - IdCardScannerView

struct IdCardScannerView: View {

    let side: IdCardSide
    @EnvironmentObject private var coordinator: AppNavigationCoordinator

    var body: some View {
        DocumentCameraView(
            onScan: { image in
                coordinator.onScanComplete?(image)
                coordinator.onScanComplete = nil
                coordinator.pop()
            },
            onCancel: {
                coordinator.onScanComplete = nil
                coordinator.pop()
            }
        )
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - DocumentCameraView (UIViewControllerRepresentable)

private struct DocumentCameraView: UIViewControllerRepresentable {

    let onScan: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    // MARK: - Coordinator / VNDocumentCameraViewControllerDelegate

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        let onScan: (UIImage) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else { onCancel(); return }
            let image = scan.imageOfPage(at: 0)
            controller.dismiss(animated: true) { [weak self] in
                self?.onScan(image)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCancel()
        }
    }
}
