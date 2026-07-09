//
//  ShowcaseCatalog.swift
//  NewTest
//
//  SDK Modül Rehberi'nin veri kaynağı. Her SDK modülü için: canlı view,
//  entegrasyon kodu ve özelleştirme kodu. ShowcaseCatalogView/DetailView bunu kullanır.
//

import SwiftUI
import IdentifySDK

// MARK: - ShowcaseItem

struct ShowcaseItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String              // SF Symbol
    /// Katalogda gruplama başlığı ("Modüller" / "Tasarım Sistemi").
    var category: String = "Modüller"
    /// Canlı SDK ekranı (mock coordinator ile çizilir).
    let liveView: () -> AnyView
    /// "Bu modül akışta nasıl yer alır / nasıl tüketilir" kod parçacığı.
    let integrationCode: String
    /// "Bu modül nasıl özelleştirilir (tema + tam view replace)" kod parçacığı.
    let customizationCode: String
}

/// Katalogdaki bölüm sırası.
let showcaseCategories = ["Modüller", "Tasarım Sistemi", "Sesli Okuma", "Olay Örgüsü / Telemetri", "Çapraz Platform (RN/Flutter)"]

// MARK: - Katalog

@MainActor
enum ShowcaseCatalog {

    static let items: [ShowcaseItem] = [
        .init(
            id: "prepare", title: "Hazırlık (Prepare)",
            subtitle: "Kullanıcıyı sürece hazırlayan bilgilendirme ekranı",
            icon: "checklist",
            liveView: { AnyView(SDKPrepareView()) },
            integrationCode: integration(route: ".prepare", view: "SDKPrepareView"),
            customizationCode: customization(route: ".prepare", custom: "PrepareExampleReplaced")
        ),
        .init(
            id: "selfie", title: "Selfie",
            subtitle: "Yüz yakalama + canlılık (liveness) ile selfie",
            icon: "person.crop.square",
            liveView: { AnyView(SDKSelfieView()) },
            integrationCode: integration(route: ".selfie", view: "SDKSelfieView"),
            customizationCode: customization(route: ".selfie", custom: "SelfieExampleReplaced")
        ),
        .init(
            id: "selfieWithLiveness", title: "Canlılıkla Selfie (ARKit)",
            subtitle: "ARKit yüz takibiyle aktif canlılık + selfie doğrulama",
            icon: "faceid",
            liveView: { AnyView(SDKSelfieWithLivenessView()) },
            integrationCode: integration(route: ".selfieWithLiveness", view: "SDKSelfieWithLivenessView"),
            customizationCode: customization(route: ".selfieWithLiveness", custom: "SwlExampleReplaced")
        ),
        .init(
            id: "idCard", title: "Kimlik Kartı (OCR)",
            subtitle: "Kimlik ön/arka tarama + OCR",
            icon: "person.text.rectangle",
            liveView: { AnyView(SDKIdCardView()) },
            integrationCode: integration(route: ".idCard", view: "SDKIdCardView"),
            customizationCode: customization(route: ".idCard", custom: "IdCardExampleReplaced")
        ),
        .init(
            id: "nfc", title: "NFC Pasaport/Kimlik",
            subtitle: "ICAO çip okuma (BAC/PACE/Secure Messaging)",
            icon: "wave.3.right.circle",
            liveView: { AnyView(SDKNfcView()) },
            integrationCode: integration(route: ".nfc", view: "SDKNfcView"),
            customizationCode: customization(route: ".nfc", custom: "NfcExampleReplaced")
        ),
        .init(
            id: "idCardOVD", title: "Kimlik OVD (Hologram)",
            subtitle: "Optik değişken (hologram/gökkuşağı) güvenlik doğrulaması",
            icon: "sparkles.rectangle.stack",
            liveView: { AnyView(SDKIdCardOVDView()) },
            integrationCode: integration(route: ".idCardOVD", view: "SDKIdCardOVDView"),
            customizationCode: customization(route: ".idCardOVD", custom: "OvdExampleReplaced")
        ),
        .init(
            id: "liveness", title: "Canlılık (Liveness)",
            subtitle: "Aktif canlılık tespiti",
            icon: "face.smiling",
            liveView: { AnyView(SDKLivenessView()) },
            integrationCode: integration(route: ".liveness", view: "SDKLivenessView"),
            customizationCode: customization(route: ".liveness", custom: "LivenessExampleReplaced")
        ),
        .init(
            id: "speech", title: "Konuşma (Speech)",
            subtitle: "Sesli ifade / konuşma tanıma adımı",
            icon: "waveform",
            liveView: { AnyView(SDKSpeechRecView()) },
            integrationCode: integration(route: ".speech", view: "SDKSpeechRecView"),
            customizationCode: customization(route: ".speech", custom: "SpeechExampleReplaced")
        ),
        .init(
            id: "addressConfirm", title: "Adres Onayı",
            subtitle: "Adres girişi + fatura/belge yükleme",
            icon: "house.circle",
            liveView: { AnyView(SDKAddressConfirmView()) },
            integrationCode: integration(route: ".addressConfirm", view: "SDKAddressConfirmView"),
            customizationCode: customization(route: ".addressConfirm", custom: "AddressConfirmExample")
        ),
        .init(
            id: "signature", title: "İmza (Signature)",
            subtitle: "El ile ıslak imza yakalama",
            icon: "signature",
            liveView: { AnyView(SDKSignatureView()) },
            integrationCode: integration(route: ".signature", view: "SDKSignatureView"),
            customizationCode: customization(route: ".signature", custom: "SignatureExampleReplaced")
        ),
        .init(
            id: "videoRecorder", title: "Video Kayıt",
            subtitle: "Onam/beyan video kaydı",
            icon: "video.circle",
            liveView: { AnyView(SDKVideoRecorderView()) },
            integrationCode: integration(route: ".videoRecorder", view: "SDKVideoRecorderView"),
            customizationCode: customization(route: ".videoRecorder", custom: "VideoRecorderExampleReplaced")
        ),
        .init(
            id: "callScreen", title: "Görüntülü Görüşme",
            subtitle: "WebRTC ile temsilci görüşmesi (bekleme + çağrı)",
            icon: "phone.circle",
            liveView: { AnyView(SDKCallScreenView()) },
            integrationCode: integration(route: ".callScreen", view: "SDKCallScreenView"),
            customizationCode: customization(route: ".callScreen", custom: "CallScreenExampleReplaced")
        ),
        .init(
            id: "thankYou", title: "Teşekkür / Sonuç",
            subtitle: "Süreç sonucu (pozitif/negatif/kaçırılmış)",
            icon: "checkmark.seal",
            liveView: { AnyView(ThankYouShowcasePreview()) },
            integrationCode: integration(route: ".thankYou(nil)", view: "SDKThankYouView"),
            customizationCode: customization(route: ".thankYou(nil)", custom: "ThankYouExampleReplaced")
        ),
        .init(
            id: "signLang", title: "İşaret Dili (opt-in)",
            subtitle: "Görüşme başında işaret dili desteği tercihi",
            icon: "hand.raised.fingers.spread",
            liveView: { AnyView(SDKSignLangView(onFinish: {})) },
            integrationCode: integrationOverlay(view: "SDKSignLangView(onFinish:)",
                note: "Bu ekran CallScreen başında, sunucu işaret dili desteği istediğinde fullScreenCover olarak otomatik sunulur."),
            customizationCode: customization(route: "/* overlay */", custom: "SignLangExampleReplaced")
        ),
        .init(
            id: "lostConnection", title: "Bağlantı Koptu",
            subtitle: "Görüşmede internet/socket kopunca yeniden bağlanma",
            icon: "wifi.exclamationmark",
            liveView: { AnyView(SDKLostConnectionView()) },
            integrationCode: integrationOverlay(view: "SDKLostConnectionView()",
                note: "Bu ekran görüşme sırasında bağlantı koptuğunda SDK tarafından otomatik sunulur; host'un tetiklemesi gerekmez."),
            customizationCode: customization(route: "/* overlay */", custom: "LostConnectionExampleReplaced")
        ),

        // MARK: Tasarım Sistemi (SDK'nın ortak UI primitifleri)
        .init(
            id: "ds_colors", title: "Renkler (Colors)",
            subtitle: "IDColor paleti — tüm token'lar SDKTheme'den okunur, host override edebilir",
            icon: "paintpalette", category: "Tasarım Sistemi",
            liveView: { AnyView(ColorsShowcaseView()) },
            integrationCode: """
            // SDK her yerde renk token'larını IDColor üzerinden okur:
            Text("Merhaba").foregroundColor(IDColor.primary)
            RoundedRectangle(cornerRadius: IDRadius.md).fill(IDColor.successBright)

            // Token'lar dark/light için adaptive yardımcılarla gelir:
            .background(IDColor.adaptiveBackground(for: colorScheme))
            .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            """,
            customizationCode: """
            // TÜM paleti host'tan override et (renkler SDKTheme.shared.colors'ta):
            SDKTheme.shared.colors.primary       = .purple
            SDKTheme.shared.colors.successBright  = Color(hex: "#1A8C73")
            SDKTheme.shared.colors.error         = .red
            // Hazır alternatif vurgular: IDColor.accentPurple / IDColor.accentTeal
            // Bu örnek uygulamada da renkler hep IDColor.* ile kullanılıyor (hardcoded RGB yok).
            """
        ),
        .init(
            id: "ds_fonts", title: "Tipografi (Fonts)",
            subtitle: "IDFont ölçeği — varsayılan Inter; host kendi fontunu register edebilir",
            icon: "textformat", category: "Tasarım Sistemi",
            liveView: { AnyView(FontsShowcaseView()) },
            integrationCode: """
            // Metinlerde IDFont ölçeğini kullan:
            Text("Başlık").font(IDFont.displayMedium(.bold))
            Text("Gövde").font(IDFont.bodyRegular())
            """,
            customizationCode: """
            // Kendi fontunu runtime'da kaydet, sonra aileyi değiştir:
            if let url = Bundle.main.url(forResource: "MyFont", withExtension: "ttf") {
                SDKTheme.shared.registerFont(at: url)
            }
            SDKTheme.shared.fonts.familyName = "MyFont"   // tüm SDK metinleri bu aileye geçer
            // familyName = nil → sistem fontu
            """
        ),
        .init(
            id: "ds_navbar", title: "Navigation Bar",
            subtitle: "SDKNavigationBar — login / module / progress / overlay stilleri",
            icon: "rectangle.topthird.inset.filled", category: "Tasarım Sistemi",
            liveView: { AnyView(NavBarShowcaseView()) },
            integrationCode: """
            // Modül başlığı + geri:
            SDKNavigationBar(style: .module, title: "Kimlik", subtitle: "Adım 2/5", onBack: { ... })
            // İlerleme çubuklu:
            SDKNavigationBar(style: .progress(steps: 5, current: 2), title: "Süreç", onBack: { ... })
            // Kamera/görüntü üstü:
            SDKNavigationBar(style: .overlay, onBack: { ... }, onHelp: { ... })
            """,
            customizationCode: """
            // Nav bar ikonları SDKTheme.shared.icons'tan gelir — host override edebilir:
            SDKTheme.shared.icons.logo      = Image("my_logo")
            SDKTheme.shared.icons.hamburger = Image("my_menu")
            // trailing: ile sağ tarafa kendi view'ını koyabilirsin.
            """
        ),
        .init(
            id: "ds_button", title: "Buton (Button)",
            subtitle: "SDKButton — primary / secondary / success / cancel + loading/disabled",
            icon: "capsule", category: "Tasarım Sistemi",
            liveView: { AnyView(ButtonsShowcaseView()) },
            integrationCode: """
            SDKButton(title: "Devam", style: .primary) { ... }
            SDKButton(title: "Vazgeç", style: .cancel) { ... }
            SDKButton(title: "Yükleniyor", style: .primary, isLoading: true) { ... }
            SDKButton(title: "Pasif", style: .primary, isDisabled: true) { ... }
            """,
            customizationCode: """
            // Buton renkleri tema token'larına bağlı (primary→IDColor.primary,
            // cancel→IDColor.error, success→IDColor.successBright). Tema rengini
            // değiştirince butonlar da otomatik değişir:
            SDKTheme.shared.colors.primary = IDColor.accentTeal
            """
        ),
        .init(
            id: "ds_alerts", title: "Uyarı (Alert)",
            subtitle: "IDAlert — info / error / success / normal + tek/çift/destructive aksiyon",
            icon: "exclamationmark.bubble", category: "Tasarım Sistemi",
            liveView: { AnyView(AlertsShowcaseView()) },
            integrationCode: """
            // Native .alert yerine SDK'nın tema uyumlu uyarısı:
            @State private var alert: IDAlertModel?

            someView
                .idAlert(item: $alert)   // model nil olunca kapanır

            alert = IDAlertModel(
                type: .error, title: "Hata",
                message: "Bir şeyler ters gitti.",
                actions: [
                    IDAlertAction(title: "İptal", style: .cancel),
                    IDAlertAction(title: "Tekrar Dene", style: .primary) { retry() }
                ]
            )

            // Bool tabanlı kısa kullanım:
            someView.idAlert(isPresented: $show, alert: IDAlertModel(
                type: .info, title: "Bilgi", message: "...",
                actions: [IDAlertAction(title: "Tamam", style: .primary)]
            ))
            """,
            customizationCode: """
            // type ikon + vurgu rengini belirler (tema token'larından):
            //   .info→primary  .error→error  .success→success  .normal→inkMid
            // İki aksiyon yan yana, üç+ aksiyon alt alta dizilir.
            // Aksiyon stilleri: .primary / .cancel / .destructive
            // message "" verilirse mesaj satırı gizlenir (yalnız başlık + aksiyon).
            """
        ),

        .init(
            id: "ds_customization", title: "Özelleştirme (Metin + İkon)",
            subtitle: "Hazır ekranların metinlerini ve ikonlarını dışarıdan override et",
            icon: "slider.horizontal.3", category: "Tasarım Sistemi",
            liveView: { AnyView(CustomizationShowcaseView()) },
            integrationCode: """
            // --- METİN ---
            // 1) Mevcut SDK metnini ez (dil bazlı):
            SDKLocalization.shared.setOverride(key: .continuePage, language: .tr, value: "İlerle")
            SDKLocalization.shared.registerOverrides([
                .de: ["Continue": "Weiter", "IdVerifyTitle": "Ausweisprüfung"]
            ])
            SDKLocalization.shared.loadOverrides(from: jsonURL, language: .en)

            // 2) Kendi yeni key'in (custom ekranlar için):
            SDKLocalization.shared.registerOverrides([.tr: ["MyKey": "Merhaba"]])
            Text(SDKLocalization.shared.string(forKey: "MyKey"))

            // --- İKON ---
            SDKTheme.shared.setIcon(.camera, Image("my_camera"))
            SDKTheme.shared.setIcons([.checkmark: Image(systemName: "checkmark.seal.fill"),
                                      .logo: Image("brand_logo")])
            SDKTheme.shared.resetIcon(.camera)   // varsayılana dön
            Image.sdk(.checkmark)                 // çözülmüş ikonu kullan
            """,
            customizationCode: """
            // METİN çözüm sırası: host override → bundle JSON (5 dil) → key'in kendisi.
            //   • Override'lar bundle'ın ÜSTÜNDE önceliklidir, aktif sdkLang'e göre çözülür.
            //   • Yeni key eklemek için enum gerekmez: registerOverrides + string(forKey:).
            // İKON çözüm sırası: setIcon override → SDKIconKey.defaultImage (SF Symbol / asset).
            //   • SDKIconKey grupları: chrome, aksiyon, izin satırı, illüstrasyon, durum.
            //   • Host custom ekranları (registry.custom) zaten kendi metin/ikonunu kullanır;
            //     bu API yalnızca SDK'nın HAZIR ekranlarını markalamak içindir.
            // NOT: Lokalizasyon reaktif değil — dili oturum başında (Login) seçip akışa girin.
            """
        ),

        // MARK: Sesli Okuma (read-aloud / erişilebilirlik)
        .init(
            id: "speech_read_aloud", title: "Sesli Okuma (Read-Aloud)",
            subtitle: "Modül yönergelerini native (Siri) sesle oku veya kendi ses kaydını çal",
            icon: "speaker.wave.2.circle",
            category: "Sesli Okuma",
            liveView: { AnyView(SpeechShowcaseView()) },
            integrationCode: """
            // Sesli okuma modül bazında SDKSpeechConfig.shared ile açılır; seslendirme
            // ekran açılışında SDKFlowHostView tarafından OTOMATİK yapılır (ekstra kod yok).

            // 1) Tümü native (Siri / sistem sesi, *_tts metnini okur):
            SDKSpeechConfig.shared.setModeForAll(.native)

            // 2) Per-modül karışık:
            SDKSpeechConfig.shared.defaultMode = .native
            SDKSpeechConfig.shared.setMode(.customAudio, for: [.selfie, .nfc])
            SDKSpeechConfig.shared.setMode(.off, for: .livenessDetection)

            // 3) Kısayol — setupSDK(ttsEnabled: true), defaultMode .off ise .native yapar.
            """,
            customizationCode: """
            // CUSTOM AUDIO — kendi ses kaydını çal:
            // Bundle'a <SDKKeyword.rawValue>.m4a koy: SelfieTts.m4a, NfcTts.m4a, PrepareTts.m4a ...
            SDKSpeechConfig.shared.audioBundle = Bundle.main       // önce burada aranır
            SDKSpeechConfig.shared.audioFileExtension = "m4a"      // mp3/wav/caf de olur
            SDKSpeechConfig.shared.setMode(.customAudio, for: .selfie)
            // Dosya yoksa otomatik native metne düşer (varsayılan açık):
            SDKSpeechConfig.shared.fallbackToNativeIfAudioMissing = true

            // NATIVE ayarları:
            SDKSpeechConfig.shared.speechRate = AVSpeechUtteranceDefaultSpeechRate
            SDKSpeechConfig.shared.pitch = 1.0
            SDKSpeechConfig.shared.voiceIdentifier = "com.apple.voice.enhanced.tr-TR.Yelda"

            // EKSTRA/ÖZEL key (ör. NFC retry) — modül VM'inden, moduna göre okur/çalar:
            speak(.nfcRetryTts, in: .nfc)   // native metin ya da NfcRetryTts.m4a
            // Yeni metni ekle/ez (XCFramework JSON'u salt-okunur; override runtime'da):
            SDKLocalization.shared.registerOverrides([.tr: ["NfcRetryTts": "Tekrar deneyin."]])
            """
        ),

        // MARK: Olay Örgüsü / Telemetri (SDK'nın birleşik olay akışı)
        .init(
            id: "event_journey", title: "Olay Örgüsü (Telemetri)",
            subtitle: "SDK ne zaman nerede ne yaptı, kullanıcı hangi ekranda çıktı, oturum nasıl kapandı",
            icon: "point.topleft.down.curvedto.point.bottomright.up",
            category: "Olay Örgüsü / Telemetri",
            liveView: { AnyView(EventJourneyView()) },
            integrationCode: """
            // SDK tüm olayları TEK bir birleşik akıştan yayınlar (SDKEvent).
            // 1) Bir dinleyici (SDKEventListener) yaz:
            final class MyEventRecorder: SDKEventListener {
                func onSDKEvent(_ event: SDKEvent) {
                    // event.name      -> "session.started", "module.Selfie.completed", "call.ended" ...
                    // event.category  -> .session / .module / .call / .network / .error / .navigation
                    // event.status    -> .presented / .completed / .failed / .skipped / .success / .abandoned
                    // event.module    -> "Selfie", "Mrz & Nfc Screen" ... (varsa)
                    // event.screen    -> kullanıcının o anki/son ekranı
                    // event.metadata  -> ["reason": ..., "statusSummary": ..., "lastScreen": ...]
                    analytics.log(event.toDictionary())   // JSON-güvenli sözlük
                }
            }

            // 2) setupSDK'dan ÖNCE bağla:
            IdentifyManager.shared.eventDelegate = recorder

            // NOT: Bu EK bir akıştır; mevcut trackingDelegate'i etkilemez.
            """,
            customizationCode: """
            // Önemli olay adları (köprülerde de aynıdır):
            //   session.started              -> oturum başladı (setupSDK)
            //   module.<Modül>.presented     -> ekran gösterildi   (lastScreen güncellenir)
            //   module.<Modül>.completed     -> modül tamamlandı
            //   module.<Modül>.failed        -> modül başarısız
            //   module.<Modül>.skipped       -> modül atlandı
            //   call.connected / call.ended  -> görüntülü çağrı durumu
            //   session.completed (.success) -> başarıyla kapandı
            //   session.failed    (.failed)  -> başarısız kapandı
            //   session.abandoned (.abandoned) -> kullanıcı terk etti (metadata.lastScreen = nerede kaldı)

            // Kullanıcı SDK'yı açıkça kapatırsa terk olayını sen de tetikleyebilirsin:
            IdentifyManager.shared.reportSessionAbandoned(reason: "user_closed")

            // React Native / Flutter köprüleri event.toDictionary()'i olduğu gibi iletir.
            // Ayrıntı (bu repoda): docs/integration/react-native ve docs/integration/flutter
            """
        ),

        // MARK: Çapraz Platform (RN/Flutter) — gömülü köprü iskeletleri (target'a eklenmez)
        .init(
            id: "cross_platform", title: "React Native & Flutter Köprüsü",
            subtitle: "Birleşik olay akışını RN ve Flutter'a taşıyan köprü iskeletleri (gömülü kod gösterimi)",
            icon: "arrow.triangle.branch",
            category: "Çapraz Platform (RN/Flutter)",
            liveView: { AnyView(CrossPlatformIntegrationView()) },
            integrationCode: """
            // Bu ekran köprü kodunu GÖMÜLÜ olarak gösterir; gerçek köprü dosyaları
            // Xcode target'ına EKLENMEZ (SampleApp derlemesini etkilemez).
            // Tam dosyalar: SampleApp/docs/integration/{react-native,flutter}/
            //
            // Akış: SDKEvent → IdentifyManager.shared.eventDelegate
            //   RN     : RCTEventEmitter.sendEvent("onSDKEvent", body: event.toDictionary())
            //   Flutter: FlutterEventChannel sink(event.toDictionary())
            """,
            customizationCode: """
            // event.toDictionary() JSON-güvenli sözlüktür; her iki köprüde de aynı şekilde
            // taşınır ve TS interface / Dart model ile birebir eşlenir. Olay adları:
            //   session.started / module.<Modül>.* / call.* / session.completed|failed|abandoned
            """
        ),
    ]

    // MARK: - Kod şablonları

    private static func integration(route: String, view: String) -> String {
        """
        // 1) VARSAYILAN
        // Modül, backend'in döndürdüğü sıraya göre akışta otomatik çizilir.
        // SDKFlowHostView, \(route) rotasını \(view)() ile eşler — host'un
        // ekstra bir şey yapmasına gerek yoktur.

        SDKFlowHostView(coordinator: coordinator, registry: registry) {
            LoginView().environmentObject(coordinator)
        }

        // Akış login'de başlar:
        //   coordinator.prepareForSetup()
        //   IdentifyManager.shared.setupSDK(... ) { _, resp, _ in
        //       if resp.result == true { coordinator.start() }
        //   }
        """
    }

    private static func integrationOverlay(view: String, note: String) -> String {
        """
        // VARSAYILAN (overlay ekran)
        // \(note)
        //
        // Yine de ekranı önizleyebilir, tema ile değiştirebilir veya
        // tamamen kendi view'ınla override edebilirsin:
        \(view)
        """
    }

    private static func customization(route: String, custom: String) -> String {
        """
        // 2) TEMA İLE ÖZELLEŞTİR (tasarım token'ları host'tan override edilir)
        SDKTheme.shared.colors.primary = .purple
        SDKTheme.shared.fonts.familyName = "Inter"

        // 3) EKRANI TAMAMEN KENDİ VIEW'INLA DEĞİŞTİR
        // RootView.configureIfNeeded() içinde:
        registry.override(\(route)) {
            \(custom)()     // kendi SwiftUI view'ın
        }
        // Kendi view'ında SDK'nın ViewModel'ini kullanarak iş mantığını korursun.

        // 4) DIŞARIDAN DEĞİŞKEN ENJEKTE ET (environment object)
        // Her modülün bir <Modül>Config: ObservableObject'i var. Developer kendi
        // değerlerini (başlık, renk, limit, ön-doldurma, doğrulama eşiği...) verir:
        let config = \(configType(for: custom))()
        config.accentColor = .green
        // config.maxAttempts = 5   // modüle göre değişen knob'lar
        \(custom)()
            .environmentObject(config)   // <-- environment object ile enjekte
        """
    }

    /// Replace view adından config tipini türetir (örn. SelfieExampleReplaced → SelfieConfig).
    private static func configType(for custom: String) -> String {
        let base = custom
            .replacingOccurrences(of: "ExampleReplaced", with: "")
            .replacingOccurrences(of: "Example", with: "")
        return base + "Config"
    }
}
