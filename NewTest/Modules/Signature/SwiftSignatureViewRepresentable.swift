//
//  SwiftSignatureViewRepresentable.swift
//  NewTest
//

import SwiftUI
import SwiftSignatureView
import PencilKit

// Signature UIView'ine imperatif erişim sağlar (clear, getCroppedSignature).
final class SignatureViewActions: ObservableObject {
    fileprivate(set) var signatureView: SwiftSignatureView?

    func getCroppedSignature() -> UIImage? {
        signatureView?.getCroppedSignature()
    }

    func clear() {
        signatureView?.clear()
    }
}

struct SwiftSignatureViewRepresentable: UIViewRepresentable {
    var actions: SignatureViewActions
    var onDraw: () -> Void

    func makeUIView(context: Context) -> SwiftSignatureView {
        let view = SwiftSignatureView()
        view.delegate = context.coordinator
        view.backgroundColor = .white
        if #available(iOS 13.0, *) {
            if let inner = view.subviews.first(where: { $0 is ISignatureView }),
               let canvas = inner.subviews.first(where: { $0 is PKCanvasView }) {
                canvas.backgroundColor = .white
            }
        }
        actions.signatureView = view
        return view
    }

    func updateUIView(_ uiView: SwiftSignatureView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDraw: onDraw)
    }

    final class Coordinator: NSObject, SwiftSignatureViewDelegate {
        var onDraw: () -> Void
        init(onDraw: @escaping () -> Void) { self.onDraw = onDraw }

        func swiftSignatureViewDidDrawGesture(_ view: ISignatureView, _ tap: UIGestureRecognizer) {}
        func swiftSignatureViewDidDraw(_ view: ISignatureView) { onDraw() }
    }
}
