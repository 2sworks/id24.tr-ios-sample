//
//  VideoFeedRepresentable.swift
//  NewTest
//
//  WebRTC UIView (remoteVideoView / localVideoView) sarmalayıcısı.
//

import SwiftUI
import UIKit

struct VideoFeedRepresentable: UIViewRepresentable {

    let videoView: UIView?
    var contentMode: UIView.ContentMode = .scaleAspectFill

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        container.clipsToBounds = true
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let videoView else {
            uiView.subviews.forEach { $0.removeFromSuperview() }
            return
        }
        guard videoView.superview !== uiView else {
            videoView.contentMode = contentMode
            return
        }
        videoView.removeFromSuperview()
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.contentMode = contentMode
        uiView.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: uiView.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor)
        ])
    }
}
