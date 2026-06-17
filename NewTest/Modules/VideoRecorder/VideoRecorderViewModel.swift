//
//  VideoRecorderViewModel.swift
//  NewTest
//
//  5 saniye video kayit ekraninin ViewModel'i.
//  SDK: upload5SecVideo
//

import Foundation
import UIKit
import IdentifySDK

@MainActor
final class VideoRecorderViewModel: BaseModuleViewModel {

    // MARK: - Published State

    /// Kaydedilen video verisi
    @Published var videoData: Data? = nil

    /// Onizleme URL (AVPlayer icin)
    @Published var videoURL: URL? = nil

    /// Yukleme tamamlandi mi
    @Published private(set) var uploadCompleted: Bool = false

    /// Video suresi limiti (saniye)
    let videoTimeLimit: TimeInterval = 5.0

    // MARK: - Video Secildi (UIImagePickerController delegate karsiligi)

    func videoSelected(url: URL) {
        videoURL = url
        videoData = try? Data(contentsOf: url)
        uploadCompleted = false
        errorMessage = nil
    }

    // MARK: - Delete

    func deleteVideo() {
        if let url = videoURL {
            try? FileManager.default.removeItem(at: url)
        }
        videoURL = nil
        videoData = nil
        uploadCompleted = false
        errorMessage = nil
    }

    // MARK: - Upload

    func uploadVideo(appState: AppStateViewModel) {
        guard let data = videoData else {
            errorMessage = "Video secilmedi"
            return
        }
        isLoading = true
        manager.upload5SecVideo(videoData: data) { [weak self] resp, webErr in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let err = webErr, err.errorMessages != "" {
                    self.errorMessage = err.errorMessages
                } else if resp?.result == true {
                    self.uploadCompleted = true
                    appState.advanceToNextModule()
                } else {
                    self.errorMessage = "Video yuklenemedi"
                }
            }
        }
    }
}
