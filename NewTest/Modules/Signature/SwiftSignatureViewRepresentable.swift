//
//  SwiftSignatureViewRepresentable.swift
//  NewTest
//

import SwiftUI
import SwiftSignatureView
import PencilKit
import CoreImage

// Signature UIView'ine imperatif erişim sağlar (clear, getCroppedSignature).
final class SignatureViewActions: ObservableObject {
    fileprivate(set) var signatureView: SwiftSignatureView?

    func getCroppedSignature() -> UIImage? {
        signatureView?.getCroppedSignature()
    }

    /// Dark mode'da çizim beyaz üzerine yapıldığı için sunucuya göndermeden önce
    /// siyah-üzeri-beyaz'a çevirir. Light mode'da olduğu gibi döner.
    func getSignatureForServer(isDark: Bool) -> UIImage? {
        guard let image = getCroppedSignature() else { return nil }
        guard isDark else { return image }
        return invertedOnWhite(image)
    }

    func clear() {
        signatureView?.clear()
    }

    private func invertedOnWhite(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let inverted = ciImage.applyingFilter("CIColorInvert")
        let context = CIContext()
        guard let cgImage = context.createCGImage(inverted, from: inverted.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct SwiftSignatureViewRepresentable: UIViewRepresentable {
    var actions: SignatureViewActions
    var onDraw: () -> Void
    var colorScheme: ColorScheme

    private static let darkCanvas = UIColor(white: 0.12, alpha: 1)

    func makeUIView(context: Context) -> SwiftSignatureView {
        let view = SwiftSignatureView()
        view.delegate = context.coordinator
        applyColors(to: view)
        actions.signatureView = view
        return view
    }

    func updateUIView(_ uiView: SwiftSignatureView, context: Context) {
        applyColors(to: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDraw: onDraw)
    }

    private func applyColors(to view: SwiftSignatureView) {
        let isDark = colorScheme == .dark
        let bg: UIColor = isDark ? Self.darkCanvas : .white
        let ink: UIColor = isDark ? .white : .black
        view.backgroundColor = bg
        view.strokeColor = ink
        if let inner = view.subviews.first(where: { $0 is ISignatureView }),
           let canvas = inner.subviews.first(where: { $0 is PKCanvasView }) {
            canvas.backgroundColor = bg
        }
    }

    final class Coordinator: NSObject, SwiftSignatureViewDelegate {
        var onDraw: () -> Void
        init(onDraw: @escaping () -> Void) { self.onDraw = onDraw }

        func swiftSignatureViewDidDrawGesture(_ view: ISignatureView, _ tap: UIGestureRecognizer) {}
        func swiftSignatureViewDidDraw(_ view: ISignatureView) { onDraw() }
    }
}
