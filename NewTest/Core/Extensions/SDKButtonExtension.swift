//
//  SDKButtonExtension.swift
//  NewTest
//
//  Created by Emir Beytekin on 27.10.2022.
//

import UIKit
import SwiftUI

class IdentifyButton: UIButton {
    enum ButtonType {
        case submit
        case cancel
        case info
        case loader
    }
    
    public typealias VoidHandler = () -> Void
    
    var onTap: VoidHandler?
    var loader: UIActivityIndicatorView!
    public var type: ButtonType? = .submit
    public var newTitle: String? = ""
    
    var btnImg: UIImage?
    private let textImageSpacing: CGFloat = 10.0
    
    var alignment: Alignment = .left
    var imageButton = false
    
    enum Alignment {
        case left
        case right
        case bottom
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func populate() {
        switch type {
            case .submit:
                cornerRadius = 3
                backgroundColor = IdentifyTheme.whiteColor
                setTitleColor(IdentifyTheme.submitBlueColor, for: .normal)
                dropShadow(color: .black, opacity: 0.3, offSet: CGSize(width: -1, height: 1), radius: 9, scale: true)
//                titleLabel?.font = .boldSystemFont(ofSize: 18)
            case .cancel:
                cornerRadius = 3
                backgroundColor = IdentifyTheme.orangeColor
                setTitleColor(IdentifyTheme.lightWhiteColor, for: .normal)
                dropShadow(color: #colorLiteral(red: 0.2907858491, green: 0.8147417903, blue: 0.9741671681, alpha: 1), opacity: 0.3, offSet: CGSize(width: -1, height: 1), radius: 9, scale: true)
            case .info:
                cornerRadius = 3
                backgroundColor = IdentifyTheme.grayColor
                setTitleColor(IdentifyTheme.lightWhiteColor, for: .normal)
                dropShadow(color: .black, opacity: 0.3, offSet: CGSize(width: -1, height: 1), radius: 9, scale: true)
        
            case .loader:
                setTitle("", for: .normal)
                loader = UIActivityIndicatorView(style: .medium)
                loader.hidesWhenStopped = true
                loader.startAnimating()
                loader.color = IdentifyTheme.darkGrayColor
                loader.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
                addSubview(loader)
            default:
                return
        }
    }
    
    func commonInit() {
        addTarget(self, action: #selector(touchUpInsideAction(button:)), for: .touchUpInside)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentHorizontalAlignment = .center
        adjustsImageWhenHighlighted = false
    }
    
    @objc func touchUpInsideAction(button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        self.onTap?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if imageButton {
            if alignment == .left {
                titleEdgeInsets = UIEdgeInsets(top: 0, left: textImageSpacing, bottom: 0, right: 0)
                contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: textImageSpacing)
            } else if alignment == .bottom {
                guard
                    let imageViewSize = self.imageView?.frame.size,
                    let titleLabelSize = self.titleLabel?.frame.size else {
                    return
                }
                let totalHeight = imageViewSize.height + titleLabelSize.height + 0
                imageEdgeInsets = UIEdgeInsets(
                    top: max(0, -(totalHeight - imageViewSize.height)),
                    left: 0.0,
                    bottom: 0.0,
                    right: -(titleLabelSize.width + imageViewSize.width)
                )
                titleEdgeInsets = UIEdgeInsets(
                    top: (totalHeight - imageViewSize.height),
                    left: 0.0,
                    bottom: -(totalHeight - titleLabelSize.height),
                    right: 0.0
                )
                contentEdgeInsets = UIEdgeInsets(
                    top: 0,
                    left: (imageViewSize.width * -1) - 8,
                    bottom: titleLabelSize.height,
                    right: -8
                )
            } else {
                if let imageView = imageView, let titleLabel = titleLabel {
                    titleEdgeInsets = UIEdgeInsets(top: 0, left: -1 * imageView.frame.size.width,
                                                   bottom: 0, right: imageView.frame.size.width)
                    imageEdgeInsets = UIEdgeInsets(top: 0, left: titleLabel.frame.size.width + textImageSpacing,
                                                   bottom: 0, right: -1 * titleLabel.frame.size.width)
                    contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: textImageSpacing)
                }
            }
            titleLabel?.sizeToFit()
        }
        
    }
    
}

// MARK: - SwiftUI ButtonStyle

/// IdentifyButton'ın SwiftUI karşılığı.
/// Kullanım: Button("Bağlan") { }.buttonStyle(IdentifyButtonStyle(type: .submit))
struct IdentifyButtonStyle: ButtonStyle {
    enum ButtonType {
        case submit
        case cancel
        case info
    }

    var type: ButtonType = .submit

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor(for: type))
            .foregroundColor(foregroundColor(for: type))
            .cornerRadius(3)
            .sdkShadow(opacity: 0.3, offset: CGSize(width: -1, height: 1), radius: 9)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundColor(for type: ButtonType) -> Color {
        switch type {
        case .submit: return Color(IdentifyTheme.whiteColor)
        case .cancel: return Color(IdentifyTheme.orangeColor)
        case .info:   return Color(IdentifyTheme.grayColor)
        }
    }

    private func foregroundColor(for type: ButtonType) -> Color {
        switch type {
        case .submit: return Color(IdentifyTheme.submitBlueColor)
        case .cancel: return Color(IdentifyTheme.lightWhiteColor)
        case .info:   return Color(IdentifyTheme.lightWhiteColor)
        }
    }
}
