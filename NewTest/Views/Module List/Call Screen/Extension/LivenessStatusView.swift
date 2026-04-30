//
//  LivenessStatusView.swift
//

import UIKit

// MARK: - LivenessStatusView

final class LivenessStatusView: UIView {

    // MARK: - Layout
    private let headerStack   = UIStackView()
    private let faceDot       = UIView()
    private let titleLabel    = UILabel()
    private let scoreLabel    = UILabel()

    private let actionGrid    = UIStackView()
    private var actionBadges: [LivenessActionType: ActionBadgeView] = [:]

    // 3 sütun × 4 satır
    private let allActions: [LivenessActionType] = [
        .eyesOpen,     .naturalBlink, .speaking,
        .squint,       .browRaise,    .browFurrow,
        .lookingAtScreen, .headTurnRight, .headTurnLeft,
        .headUp,       .headDown,     .headTilt
    ]

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = UIColor.black.withAlphaComponent(0.82)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        setupHeader()
        setupActionGrid()
        setupConstraints()
    }

    private func setupHeader() {
        faceDot.backgroundColor = .systemRed
        faceDot.layer.cornerRadius = 5
        faceDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            faceDot.widthAnchor.constraint(equalToConstant: 10),
            faceDot.heightAnchor.constraint(equalToConstant: 10)
        ])

        titleLabel.text = "LIVENESS"
        titleLabel.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        titleLabel.textColor = .white

        scoreLabel.text = "–"
        scoreLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        scoreLabel.textColor = UIColor.white.withAlphaComponent(0.3)
        scoreLabel.textAlignment = .right

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 6
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(faceDot)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(spacer)
        headerStack.addArrangedSubview(scoreLabel)
        addSubview(headerStack)
    }

    private func setupActionGrid() {
        actionGrid.axis         = .vertical
        actionGrid.spacing      = 4
        actionGrid.distribution = .fillEqually
        actionGrid.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionGrid)

        for row in 0..<4 {
            let rowStack = UIStackView()
            rowStack.axis         = .horizontal
            rowStack.spacing      = 4
            rowStack.distribution = .fillEqually

            for col in 0..<3 {
                let index = row * 3 + col
                let action = allActions[index]
                let badge  = ActionBadgeView(action: action)
                actionBadges[action] = badge
                rowStack.addArrangedSubview(badge)
            }
            actionGrid.addArrangedSubview(rowStack)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            actionGrid.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            actionGrid.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            actionGrid.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            actionGrid.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Public Update API

    func updateScore(_ score: Int) {
        scoreLabel.text = "\(score) / 100"
        let t = CGFloat(score) / 100.0
        scoreLabel.textColor = UIColor(
            red:   CGFloat(max(0.0, 1.0 - t * 2.0)),
            green: CGFloat(min(1.0, 0.4 + t * 0.6)),
            blue:  0.2,
            alpha: 1.0
        )
    }

    func updateFacePresence(_ isPresent: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.faceDot.backgroundColor = isPresent ? .systemGreen : .systemRed
        }
    }

    func updateTracking(elapsed: Int, required: Int) {}

    func markActionDetected(_ action: LivenessActionType) {
        actionBadges[action]?.setDetected(true)
    }

    func flashAction(_ action: LivenessActionType) {
        actionBadges[action]?.flash()
    }

    func resetAll() {
        updateScore(0)
        updateFacePresence(false)

        actionBadges.values.forEach { $0.setDetected(false) }
    }
}

// MARK: - ActionBadgeView

private final class ActionBadgeView: UIView {

    private let emojiLabel = UILabel()
    private let nameLabel  = UILabel()
    private let checkLabel = UILabel()

    init(action: LivenessActionType) {
        super.init(frame: .zero)
        setup(action: action)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup(action: LivenessActionType) {
        backgroundColor    = UIColor.white.withAlphaComponent(0.07)
        layer.cornerRadius = 6
        layer.masksToBounds = true

        emojiLabel.text      = Self.emoji(for: action)
        emojiLabel.font      = .systemFont(ofSize: 14)
        emojiLabel.textAlignment = .center

        nameLabel.text       = Self.shortName(for: action)
        nameLabel.font       = .monospacedSystemFont(ofSize: 8, weight: .regular)
        nameLabel.textColor  = UIColor.white.withAlphaComponent(0.45)
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7

        checkLabel.text      = "·"
        checkLabel.font      = .monospacedSystemFont(ofSize: 10, weight: .bold)
        checkLabel.textColor = UIColor.white.withAlphaComponent(0.25)
        checkLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [emojiLabel, nameLabel, checkLabel])
        stack.axis         = .vertical
        stack.spacing      = 1
        stack.alignment    = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
        ])
    }

    func setDetected(_ detected: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = detected
                ? UIColor(red: 0.08, green: 0.45, blue: 0.18, alpha: 0.65)
                : UIColor.white.withAlphaComponent(0.07)
            self.checkLabel.text      = detected ? "✓" : "·"
            self.checkLabel.textColor = detected
                ? UIColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 1.0)
                : UIColor.white.withAlphaComponent(0.25)
            self.nameLabel.textColor  = detected
                ? UIColor.white.withAlphaComponent(0.9)
                : UIColor.white.withAlphaComponent(0.45)
        }
    }

    func flash() {
        UIView.animate(withDuration: 0.08, animations: {
            self.backgroundColor = UIColor(red: 0.2, green: 1.0, blue: 0.45, alpha: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.5) {
                self.backgroundColor = UIColor(red: 0.08, green: 0.45, blue: 0.18, alpha: 0.65)
            }
        }
    }

    private static func emoji(for action: LivenessActionType) -> String {
        switch action {
        case .eyesOpen:        return "👀"
        case .naturalBlink:    return "😑"
        case .speaking:        return "🗣"
        case .squint:          return "😤"
        case .browRaise:       return "🙋"
        case .browFurrow:      return "😠"
        case .lookingAtScreen: return "👁"
        case .headTurnRight:   return "➡️"
        case .headTurnLeft:    return "⬅️"
        case .headUp:          return "⬆️"
        case .headDown:        return "⬇️"
        case .headTilt:        return "↗️"
        }
    }

    private static func shortName(for action: LivenessActionType) -> String {
        switch action {
        case .eyesOpen:        return "Gözler"
        case .naturalBlink:    return "Kırpma"
        case .speaking:        return "Konuşma"
        case .squint:          return "Kısık"
        case .browRaise:       return "Kaş ↑"
        case .browFurrow:      return "Kaş ↓"
        case .lookingAtScreen: return "Ekrana"
        case .headTurnRight:   return "Sağa"
        case .headTurnLeft:    return "Sola"
        case .headUp:          return "Yukarı"
        case .headDown:        return "Aşağı"
        case .headTilt:        return "Eğik"
        }
    }
}
