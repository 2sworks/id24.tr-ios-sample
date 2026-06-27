//
//  IdentifySdk.ts
//  React Native sarmalayıcı — IdentifySDK
//
//  Native köprüyü (IdentifySdkModule) tip-güvenli bir API ile sarar ve birleşik
//  olay akışını (SDKEvent) JS tarafında dinlemeyi sağlar.
//

import {
  NativeModules,
  NativeEventEmitter,
  EmitterSubscription,
} from 'react-native';

const { IdentifySdkModule } = NativeModules;
const emitter = new NativeEventEmitter(IdentifySdkModule);

// MARK: - Olay tipleri (native SDKEvent.toDictionary() ile birebir)

export type SDKEventCategory =
  | 'session'
  | 'module'
  | 'call'
  | 'network'
  | 'error'
  | 'navigation';

export type SDKEventStatus =
  | 'info'
  | 'presented'
  | 'completed'
  | 'failed'
  | 'skipped'
  | 'success'
  | 'abandoned'
  | 'notFound';

export interface SDKEvent {
  /** "session.started", "module.Selfie.completed", "call.ended" ... */
  name: string;
  category: SDKEventCategory;
  status: SDKEventStatus;
  /** İlgili modül (SdkModules rawValue), session/call'da olmayabilir. */
  module?: string;
  /** Kullanıcının o anki / son ekranı. */
  screen?: string;
  sessionId: string;
  timestampMs: number;
  message?: string;
  /** reason, statusSummary, lastScreen ... */
  metadata: Record<string, string>;
}

// MARK: - setupSDK parametreleri

export interface SetupOptions {
  identId: string;
  baseApiUrl: string;
  turnKey: string;
  signLangSupport?: boolean;
  nfcMaxErrorCount?: number;
  /** SdkModules rawValue listesi; boş = backend sırası. */
  selectedModules?: string[];
  wsSecretKey?: string;
  showThankYouPage?: boolean;
  showNFCNotFoundPage?: boolean;
  supportU18?: boolean;
}

// MARK: - Public API

export const IdentifySdk = {
  /** SDK'yı başlatır. Çözülürse { result } döner. */
  setupSDK(options: SetupOptions): Promise<{ result: boolean }> {
    return IdentifySdkModule.setupSDK(options);
  },

  /** Birleşik olay akışına abone olur. `subscription.remove()` ile bırakılır. */
  addEventListener(handler: (event: SDKEvent) => void): EmitterSubscription {
    return emitter.addListener('onSDKEvent', handler);
  },

  /** Kullanıcı SDK'yı açıkça kapatınca terk olayı tetiklemek için. */
  reportAbandoned(reason?: string): void {
    IdentifySdkModule.reportAbandoned(reason ?? null);
  },
};

// Bilinen olay adları (switch'lerde tip yardımı için).
export const SDKEventName = {
  sessionStarted: 'session.started',
  sessionCompleted: 'session.completed',
  sessionFailed: 'session.failed',
  sessionAbandoned: 'session.abandoned',
  callConnected: 'call.connected',
  callEnded: 'call.ended',
} as const;
