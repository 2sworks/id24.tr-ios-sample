//
//  IdentifySdkModule.m
//  React Native köprü kaydı — IdentifySDK
//
//  Swift sınıfını React Native'e tanıtır. Swift tarafı RCTEventEmitter'dan türediği
//  için olay yayını (onSDKEvent) otomatik çalışır.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(IdentifySdkModule, RCTEventEmitter)

RCT_EXTERN_METHOD(setupSDK:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(reportAbandoned:(NSString *)reason)

@end
