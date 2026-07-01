//
//  SpeechShowcaseView.swift
//  NewTest
//
//  SDK'nın SESLİ OKUMA (read-aloud) yeteneğinin canlı demosu. İki adımlı model:
//    • .native      → iOS AVSpeechSynthesizer (Siri/sistem sesi) *_tts metnini okur
//    • .customAudio → host bundle'ındaki <key>.m4a klibi çalar; yoksa native'e düşer
//    • .off         → sessiz
//
//  Konfig SDKSpeechConfig.shared üzerinden per-modül yapılır; seslendirme
//  SDKSpeechService.shared ile tetiklenir. Bu ekran modu değiştirip örnek metni okutur.
//

import SwiftUI
import IdentifySDK

struct SpeechShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Demoda seslendirilecek örnek modül (Selfie) ve onun *_tts key'i.
    private let sampleModule: SdkModules = .selfie
    private let sampleKey: SDKKeyword = .selfieTts
    private var sampleText: String { SDKLocalization.shared.translate(sampleKey) }

    @State private var mode: ModeOption = .native

    enum ModeOption: String, CaseIterable, Identifiable {
        case native = "Native (Siri)"
        case customAudio = "Custom Audio"
        case off = "Kapalı"
        var id: String { rawValue }
        var configMode: SDKSpeechConfig.Mode {
            switch self {
            case .native:      return .native
            case .customAudio: return .customAudio
            case .off:         return .off
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: IDSpacing.lg) {
                intro
                modePicker
                sampleCard
                actions
                note
            }
            .padding(IDSpacing.lg)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onDisappear { SDKSpeechService.shared.stop() }
    }

    // MARK: - Bölümler

    private var intro: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Sesli Okuma (Read-Aloud)")
                .font(IDFont.displaySmall(.bold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Text("Her modül ekranı açıldığında yönerge metni sesli okunabilir. Modu modül "
                 + "bazında seçersiniz; native sistem sesini kullanır, custom audio ise kendi "
                 + "kaydınızı çalar (dosya yoksa native'e düşer).")
                .font(IDFont.bodyRegular())
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Mod (\(sampleModule.rawValue))")
                .font(IDFont.bodyMedium(.medium))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Picker("Mod", selection: $mode) {
                ForEach(ModeOption.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var sampleCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Okunacak metin (SelfieTts)")
                .font(IDFont.caption())
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            Text(sampleText)
                .font(IDFont.bodyRegular())
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Text("Custom audio dosyası: SelfieTts.\(SDKSpeechConfig.shared.audioFileExtension)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(IDColor.inkMid)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(IDSpacing.md)
        .background(RoundedRectangle(cornerRadius: IDRadius.md).fill(IDColor.inkSurface))
        .overlay(RoundedRectangle(cornerRadius: IDRadius.md).stroke(IDColor.inkBorder, lineWidth: 1))
    }

    private var actions: some View {
        HStack(spacing: IDSpacing.md) {
            SDKButton(title: "Oku / Çal", style: .primary) { play() }
            SDKButton(title: "Durdur", style: .cancel) { SDKSpeechService.shared.stop() }
        }
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: IDSpacing.xs) {
            Text("Not")
                .font(IDFont.bodyMedium(.medium))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Text("• Custom Audio seçili ama bundle'da SelfieTts klibi yoksa, otomatik olarak "
                 + "native okuma devreye girer (fallbackToNativeIfAudioMissing).\n"
                 + "• Gerçek akışta seslendirme, ekran açılışında SDKFlowHostView tarafından "
                 + "otomatik yapılır; host'un ekstra kod yazması gerekmez.")
                .font(IDFont.bodySmall())
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
        }
    }

    // MARK: - Aksiyon

    private func play() {
        // Demoda örnek modülün modunu seçilen değere ayarla, sonra o modül bağlamında oku.
        SDKSpeechConfig.shared.setMode(mode.configMode, for: sampleModule)
        SDKSpeechService.shared.speak(sampleKey, in: sampleModule)
    }
}
