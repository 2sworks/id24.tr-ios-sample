//
//  identify_sdk.dart
//  Flutter sarmalayıcı — IdentifySDK
//
//  Native plugin köprüsünü (MethodChannel + EventChannel) tip-güvenli bir Dart API ile
//  sarar. Birleşik olay akışını (SDKEvent) bir Stream olarak sunar.
//

import 'dart:async';
import 'package:flutter/services.dart';

// MARK: - Olay tipleri (native SDKEvent.toDictionary() ile birebir)

enum SDKEventCategory { session, module, call, network, error, navigation, unknown }

enum SDKEventStatus {
  info,
  presented,
  completed,
  failed,
  skipped,
  success,
  abandoned,
  notFound,
  unknown,
}

SDKEventCategory _categoryFrom(String? v) {
  switch (v) {
    case 'session':
      return SDKEventCategory.session;
    case 'module':
      return SDKEventCategory.module;
    case 'call':
      return SDKEventCategory.call;
    case 'network':
      return SDKEventCategory.network;
    case 'error':
      return SDKEventCategory.error;
    case 'navigation':
      return SDKEventCategory.navigation;
    default:
      return SDKEventCategory.unknown;
  }
}

SDKEventStatus _statusFrom(String? v) {
  switch (v) {
    case 'info':
      return SDKEventStatus.info;
    case 'presented':
      return SDKEventStatus.presented;
    case 'completed':
      return SDKEventStatus.completed;
    case 'failed':
      return SDKEventStatus.failed;
    case 'skipped':
      return SDKEventStatus.skipped;
    case 'success':
      return SDKEventStatus.success;
    case 'abandoned':
      return SDKEventStatus.abandoned;
    case 'notFound':
      return SDKEventStatus.notFound;
    default:
      return SDKEventStatus.unknown;
  }
}

class SDKEvent {
  /// "session.started", "module.Selfie.completed", "call.ended" ...
  final String name;
  final SDKEventCategory category;
  final SDKEventStatus status;
  final String? module;
  final String? screen;
  final String sessionId;
  final int timestampMs;
  final String? message;
  final Map<String, String> metadata;

  SDKEvent({
    required this.name,
    required this.category,
    required this.status,
    required this.sessionId,
    required this.timestampMs,
    this.module,
    this.screen,
    this.message,
    this.metadata = const {},
  });

  factory SDKEvent.fromMap(Map<dynamic, dynamic> map) {
    final rawMeta = (map['metadata'] as Map?) ?? const {};
    return SDKEvent(
      name: map['name'] as String? ?? '',
      category: _categoryFrom(map['category'] as String?),
      status: _statusFrom(map['status'] as String?),
      module: map['module'] as String?,
      screen: map['screen'] as String?,
      sessionId: map['sessionId'] as String? ?? '',
      timestampMs: (map['timestampMs'] as num?)?.toInt() ?? 0,
      message: map['message'] as String?,
      metadata: rawMeta.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}

// MARK: - setupSDK parametreleri

class SetupOptions {
  final String identId;
  final String baseApiUrl;
  final String turnKey;
  final bool signLangSupport;
  final int nfcMaxErrorCount;

  /// SdkModules rawValue listesi; boş = backend sırası.
  final List<String> selectedModules;
  final String? wsSecretKey;
  final bool showThankYouPage;
  final bool showNFCNotFoundPage;
  final bool supportU18;

  const SetupOptions({
    required this.identId,
    required this.baseApiUrl,
    required this.turnKey,
    this.signLangSupport = false,
    this.nfcMaxErrorCount = 3,
    this.selectedModules = const [],
    this.wsSecretKey,
    this.showThankYouPage = false,
    this.showNFCNotFoundPage = false,
    this.supportU18 = false,
  });

  Map<String, dynamic> toMap() => {
        'identId': identId,
        'baseApiUrl': baseApiUrl,
        'turnKey': turnKey,
        'signLangSupport': signLangSupport,
        'nfcMaxErrorCount': nfcMaxErrorCount,
        'selectedModules': selectedModules,
        'wsSecretKey': wsSecretKey,
        'showThankYouPage': showThankYouPage,
        'showNFCNotFoundPage': showNFCNotFoundPage,
        'supportU18': supportU18,
      };
}

// MARK: - Public API

class IdentifySdk {
  static const MethodChannel _methods = MethodChannel('identify_sdk/methods');
  static const EventChannel _events = EventChannel('identify_sdk/events');

  Stream<SDKEvent>? _eventStream;

  /// Birleşik olay akışı. İlk dinlemede native EventChannel'a bağlanır.
  Stream<SDKEvent> get events {
    _eventStream ??= _events
        .receiveBroadcastStream()
        .map((e) => SDKEvent.fromMap(e as Map));
    return _eventStream!;
  }

  /// SDK'yı başlatır. { 'result': bool } döner.
  Future<bool> setupSDK(SetupOptions options) async {
    final res = await _methods.invokeMethod<Map>('setupSDK', options.toMap());
    return (res?['result'] as bool?) ?? false;
  }

  /// Kullanıcı SDK'yı açıkça kapatınca terk olayı tetiklemek için.
  Future<void> reportAbandoned([String? reason]) {
    return _methods.invokeMethod('reportAbandoned', {'reason': reason});
  }
}
