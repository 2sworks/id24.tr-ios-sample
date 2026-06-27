//
//  CrossPlatformIntegrationView.swift
//  NewTest
//
//  "Çapraz Platform (RN/Flutter)" rehber ekranı. React Native ve Flutter köprü
//  iskeletlerini SampleApp içinde GÖMÜLÜ KOD olarak gösterir — gerçek .swift/.m/.ts/.dart
//  dosyaları Xcode target'ına EKLENMEZ (derlemeyi etkilemez); burada yalnızca metin/kod
//  parçacığı olarak sunulur. Tam dosyalar: SampleApp/docs/integration/.
//

import SwiftUI
import IdentifySDK

struct CrossPlatformIntegrationView: View {

    enum Platform: String, CaseIterable, Identifiable {
        case reactNative = "React Native"
        case flutter = "Flutter"
        var id: String { rawValue }
    }

    @State private var platform: Platform = .reactNative
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: IDSpacing.lg) {

                Text("SDK'nın birleşik olay akışı (SDKEvent) RN ve Flutter köprülerine olduğu gibi taşınır. Aşağıdaki köprü iskeletlerini kopyalayıp projenize ekleyin. Tam dosyalar: SampleApp/docs/integration/")
                    .font(IDFont.bodySmall())
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))

                Picker("Platform", selection: $platform) {
                    ForEach(Platform.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch platform {
                case .reactNative:
                    ShowcaseCodeBlock(title: "1) Kurulum", code: Self.rnInstall)
                    ShowcaseCodeBlock(title: "2) Native köprü (IdentifySdkModule.swift)", code: Self.rnBridge)
                    ShowcaseCodeBlock(title: "3) Köprü kaydı (IdentifySdkModule.m)", code: Self.rnObjC)
                    ShowcaseCodeBlock(title: "4) JS kullanımı (IdentifySdk.ts)", code: Self.rnUsage)
                case .flutter:
                    ShowcaseCodeBlock(title: "1) Kanal kaydı (IdentifySdkPlugin.swift)", code: Self.flutterPlugin)
                    ShowcaseCodeBlock(title: "2) Dart sarmalayıcı (identify_sdk.dart)", code: Self.flutterDart)
                    ShowcaseCodeBlock(title: "3) Dart kullanımı", code: Self.flutterUsage)
                }

                eventTable
            }
            .padding(IDSpacing.md)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme))
    }

    private var eventTable: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Olay adları (her iki platformda da aynı)")
                .font(IDFont.bodySmall(.semibold))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            ShowcaseCodeBlock(title: "SDKEvent.name", code: Self.eventNames)
        }
    }

    // MARK: - React Native

    static let rnInstall = """
    # SPM (önerilen): Xcode → File → Add Packages →
    #   https://github.com/2sworks/id24.tr-ios-sdk-spm
    # Info.plist: NSCameraUsageDescription / NSMicrophoneUsageDescription
    #             NFCReaderUsageDescription (+ NFC entitlement)
    """

    static let rnBridge = """
    @objc(IdentifySdkModule)
    class IdentifySdkModule: RCTEventEmitter, SDKEventListener {
      override func supportedEvents() -> [String]! { ["onSDKEvent"] }

      override func startObserving() {
        IdentifyManager.shared.eventDelegate = self   // birleşik akışa bağlan
      }
      override func stopObserving() {
        if IdentifyManager.shared.eventDelegate === self {
          IdentifyManager.shared.eventDelegate = nil
        }
      }

      // SDKEventListener — olayı JS'e olduğu gibi (JSON) ilet
      func onSDKEvent(_ event: SDKEvent) {
        sendEvent(withName: "onSDKEvent", body: event.toDictionary())
      }

      @objc(setupSDK:resolver:rejecter:)
      func setupSDK(_ o: NSDictionary,
                    resolver resolve: @escaping RCTPromiseResolveBlock,
                    rejecter reject: @escaping RCTPromiseRejectBlock) {
        IdentifyManager.shared.setupSDK(
          identId: o["identId"] as! String,
          baseApiUrl: o["baseApiUrl"] as! String,
          networkOptions: SDKNetworkOptions(timeoutIntervalForRequest: 30,
                                            timeoutIntervalForResource: 30,
                                            useSslPinning: false),
          kpsData: nil,
          signLangSupport: o["signLangSupport"] as? Bool ?? false,
          nfcMaxErrorCount: o["nfcMaxErrorCount"] as? Int ?? 3,
          turnKey: o["turnKey"] as! String
        ) { _, room, err in
          err == nil ? resolve(["result": room.result ?? false])
                     : reject("E_SETUP", err!.localizedDescription, err)
        }
      }
    }
    """

    static let rnObjC = """
    #import <React/RCTBridgeModule.h>
    #import <React/RCTEventEmitter.h>

    @interface RCT_EXTERN_MODULE(IdentifySdkModule, RCTEventEmitter)
    RCT_EXTERN_METHOD(setupSDK:(NSDictionary *)options
                      resolver:(RCTPromiseResolveBlock)resolve
                      rejecter:(RCTPromiseRejectBlock)reject)
    @end
    """

    static let rnUsage = """
    import { IdentifySdk, SDKEvent } from './IdentifySdk';

    const sub = IdentifySdk.addEventListener((e: SDKEvent) => {
      switch (e.name) {
        case 'session.started':   break;
        case 'session.completed': /* e.status === 'success' */ break;
        case 'session.failed':    /* e.metadata.reason */ break;
        case 'session.abandoned': /* e.metadata.lastScreen */ break;
      }
    });

    await IdentifySdk.setupSDK({
      identId: 'XXXX-XXXX', baseApiUrl: 'https://api.example.com/',
      turnKey: 'turn-secret', signLangSupport: false, nfcMaxErrorCount: 3,
    });
    // sub.remove();
    """

    // MARK: - Flutter

    static let flutterPlugin = """
    public class IdentifySdkPlugin: NSObject, FlutterPlugin,
                                    SDKEventListener, FlutterStreamHandler {
      private var sink: FlutterEventSink?

      public static func register(with reg: FlutterPluginRegistrar) {
        let i = IdentifySdkPlugin()
        let m = FlutterMethodChannel(name: "identify_sdk/methods",
                                     binaryMessenger: reg.messenger())
        reg.addMethodCallDelegate(i, channel: m)
        FlutterEventChannel(name: "identify_sdk/events",
                            binaryMessenger: reg.messenger()).setStreamHandler(i)
      }

      public func onListen(withArguments a: Any?, eventSink s: @escaping FlutterEventSink) -> FlutterError? {
        sink = s; IdentifyManager.shared.eventDelegate = self; return nil
      }
      public func onCancel(withArguments a: Any?) -> FlutterError? {
        sink = nil
        if IdentifyManager.shared.eventDelegate === self { IdentifyManager.shared.eventDelegate = nil }
        return nil
      }
      // SDKEventListener — olayı Dart'a (JSON) ilet
      public func onSDKEvent(_ event: SDKEvent) {
        DispatchQueue.main.async { [weak self] in self?.sink?(event.toDictionary()) }
      }
    }
    """

    static let flutterDart = """
    class SDKEvent {
      final String name;                  // "session.started" ...
      final String category, status, sessionId;
      final String? module, screen, message;
      final int timestampMs;
      final Map<String, String> metadata;
      factory SDKEvent.fromMap(Map m) => SDKEvent(/* m['name'], m['category'] ... */);
    }

    class IdentifySdk {
      static const _m = MethodChannel('identify_sdk/methods');
      static const _e = EventChannel('identify_sdk/events');
      Stream<SDKEvent> get events =>
        _e.receiveBroadcastStream().map((x) => SDKEvent.fromMap(x as Map));
      Future<bool> setupSDK(Map<String, dynamic> o) async =>
        (await _m.invokeMethod('setupSDK', o))?['result'] ?? false;
    }
    """

    static let flutterUsage = """
    final sdk = IdentifySdk();
    final sub = sdk.events.listen((e) {
      switch (e.name) {
        case 'session.completed': /* e.status == success */ break;
        case 'session.abandoned': /* e.metadata['lastScreen'] */ break;
      }
    });
    await sdk.setupSDK({
      'identId': 'XXXX-XXXX', 'baseApiUrl': 'https://api.example.com/',
      'turnKey': 'turn-secret', 'signLangSupport': false, 'nfcMaxErrorCount': 3,
    });
    // await sub.cancel();
    """

    static let eventNames = """
    session.started                       // setupSDK
    module.<Modül>.presented/completed/failed/skipped
    call.connected / call.ended
    session.completed   (status: success) // başarıyla kapandı
    session.failed      (status: failed)  // başarısız kapandı
    session.abandoned   (status: abandoned, metadata.lastScreen = nerede kaldı)
    """
}

#Preview {
    CrossPlatformIntegrationView()
}
