//
//  CaptureSession+Flash.swift
//  WeScan
//
//  Created by Julian Schiavo on 28/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import AVFoundation

/// Extension to CaptureSession to manage the device flashlight
extension CaptureSession {
    /// The possible states that the current device's flashlight can be in
    enum FlashState {
        case on
        case off
        case unavailable
        case unknown
    }

    /// Toggles the current device's flashlight on or off.
    /// Thread-safe: Torch ayarları doğru şekilde yapılır, session'ı bloklamaz
    func toggleFlash() -> FlashState {
        guard let device = device as? AVCaptureDevice, device.isTorchAvailable else { return .unavailable }
        
        // Device'ın session'a bağlı olduğundan emin ol
        guard device.isConnected else {
            return .unavailable
        }
        
        // Mevcut torch durumunu kontrol et
        let currentMode = device.torchMode
        let newMode: AVCaptureDevice.TorchMode = (currentMode == .on) ? .off : .on
        
        do {
            // Device'ı lock et (kısa süreli, session'ı bloklamaz)
            try device.lockForConfiguration()
            
            // Torch modunu değiştir
            device.torchMode = newMode
            
            // Hemen unlock et (session'ın devam etmesi için)
            device.unlockForConfiguration()
            
            // Yeni durumu döndür
            return (newMode == .on) ? .on : .off
        } catch {
            // Lock başarısız olursa mevcut durumu döndür
            return (currentMode == .on) ? .on : .off
        }
    }
}
