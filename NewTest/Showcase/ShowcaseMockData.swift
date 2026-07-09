//
//  ShowcaseMockData.swift
//  NewTest
//
//  Showcase (SDK Modül Rehberi) için mock oturum verisi.
//
//  SDK ekranlarının bir kısmı içeriğini backend oturumundan (IdentifyManager
//  üzerindeki state) okur: konuşma cümlesi, video okuma metni, NFC ön-doldurma,
//  sıra/bekleme bilgisi, izinli belge türleri... Showcase'te gerçek oturum
//  olmadığından bu ekranlar boş/anlamsız görünür ve test edilemez.
//
//  ShowcaseMockData.apply() katalog açılırken gerçekçi örnek değerleri singleton'a
//  yazar (önceki değerlerin anlık görüntüsünü alarak); restore() katalog kapanırken
//  hepsini geri yükler — böylece mock değerler sonraki GERÇEK oturuma sızmaz.
//

import SwiftUI
import IdentifySDK

// MARK: - ShowcaseMockData

@MainActor
enum ShowcaseMockData {

    // MARK: Snapshot (geri yükleme için)

    private struct Snapshot {
        let speechExpectedSentence: String
        let videoRecordSpeechEnabled: Bool
        let videoRecordReadText: String
        let videoRecordDurationSeconds: TimeInterval
        let useKpsData: Bool
        let mrzDocNo: String
        let mrzBirthDay: String
        let mrzValidDate: String
        let queueStatsInfo: (order: String, min: String)
        let allowedCardType: [CardType]
        let selectedCardType: CardType?
        let needSpeedTest: Bool?
        let nfcComparisonCount: Int
        let selfieComparisonCount: Int
        let ocrComparisonCount: Int
    }

    private static var snapshot: Snapshot?

    /// Mock aktif mi? (Katalog açıkken true.)
    static var isActive: Bool { snapshot != nil }

    // MARK: Apply / Restore

    /// Katalog açılırken çağrılır: önce mevcut değerlerin anlık görüntüsünü alır,
    /// sonra ekranların test edilebilir görünmesi için örnek verileri yazar.
    static func apply() {
        guard snapshot == nil else { return }   // zaten aktif (yeniden girişte üst üste yazma)
        let m = IdentifyManager.shared

        snapshot = Snapshot(
            speechExpectedSentence: m.speechExpectedSentence,
            videoRecordSpeechEnabled: m.videoRecordSpeechEnabled,
            videoRecordReadText: m.videoRecordReadText,
            videoRecordDurationSeconds: m.videoRecordDurationSeconds,
            useKpsData: m.useKpsData,
            mrzDocNo: m.mrzDocNo,
            mrzBirthDay: m.mrzBirthDay,
            mrzValidDate: m.mrzValidDate,
            queueStatsInfo: m.queueStatsInfo,
            allowedCardType: m.allowedCardType,
            selectedCardType: m.selectedCardType,
            needSpeedTest: m.needSpeedTest,
            nfcComparisonCount: m.nfcComparisonCount,
            selfieComparisonCount: m.selfieComparisonCount,
            ocrComparisonCount: m.ocrComparisonCount
        )

        // Konuşma tanıma (Speech) — okunacak/soylenecek cümle sunucudan gelir.
        m.speechExpectedSentence = "Bugün hava çok güzel ve kimliğimi onaylıyorum"

        // Video kayıt — sesli okuma doğrulamalı varyantı göster (cümle + süre).
        m.videoRecordSpeechEnabled = true
        m.videoRecordReadText = "Kendi rızamla uzaktan kimlik tespiti yaptırıyorum"
        m.videoRecordDurationSeconds = 8

        // NFC — MRZ alanları ön-dolu gelsin (seri no + doğum + geçerlilik, YYMMDD).
        m.useKpsData = true
        m.mrzDocNo = "A12B34567"
        m.mrzBirthDay = "900101"
        m.mrzValidDate = "300101"

        // Görüşme bekleme ekranı — sırada 3. kişi, ~5 dk bekleme.
        m.queueStatsInfo = (order: "3", min: "5")

        // Kimlik ekranı — üç belge türü de seçilebilir görünsün.
        m.allowedCardType = [.idCard, .passport, .oldSchool]
        m.selectedCardType = .idCard

        // Hazırlık — hız testi kapalı (backend'siz takılmasın).
        m.needSpeedTest = false

        // Deneme hakları — "hak tükendi" dallarına düşülmesin.
        m.nfcComparisonCount = 5
        m.selfieComparisonCount = 5
        m.ocrComparisonCount = 5
    }

    /// Katalog kapanırken çağrılır: apply() öncesi değerleri geri yükler.
    static func restore() {
        guard let s = snapshot else { return }
        let m = IdentifyManager.shared

        m.speechExpectedSentence = s.speechExpectedSentence
        m.videoRecordSpeechEnabled = s.videoRecordSpeechEnabled
        m.videoRecordReadText = s.videoRecordReadText
        m.videoRecordDurationSeconds = s.videoRecordDurationSeconds
        m.useKpsData = s.useKpsData
        m.mrzDocNo = s.mrzDocNo
        m.mrzBirthDay = s.mrzBirthDay
        m.mrzValidDate = s.mrzValidDate
        m.queueStatsInfo = s.queueStatsInfo
        m.allowedCardType = s.allowedCardType
        m.selectedCardType = s.selectedCardType
        m.needSpeedTest = s.needSpeedTest
        m.nfcComparisonCount = s.nfcComparisonCount
        m.selfieComparisonCount = s.selfieComparisonCount
        m.ocrComparisonCount = s.ocrComparisonCount

        snapshot = nil
    }
}

// MARK: - ThankYou varyant önizlemesi

/// ThankYou ekranının üç sonucunu (başarılı / cevapsız / başarısız) tek önizlemede
/// gezilebilir yapar. Gerçek akışta statü görüşme/oturum sonucundan gelir; showcase'te
/// segment ile seçilir.
struct ThankYouShowcasePreview: View {

    @State private var selection: Int = 0

    private var status: ThankYouStatus {
        switch selection {
        case 1:  return .missedCall
        case 2:  return .notCompleted
        default: return .completed
        }
    }

    var body: some View {
        VStack(spacing: IDSpacing.md) {
            SDKThankYouView(status: status)
                .id(selection)   // segment değişince ekran yeni statüyle yeniden kurulur

            // Seçici altta: üstte olsaydı önizleme kutusunun "CANLI" rozetiyle çakışırdı.
            Picker("Sonuç", selection: $selection) {
                Text("Başarılı").tag(0)
                Text("Cevapsız").tag(1)
                Text("Başarısız").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, IDSpacing.md)
            .padding(.bottom, IDSpacing.sm)
        }
    }
}
