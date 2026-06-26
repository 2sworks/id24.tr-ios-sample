//
//  VideoRecorderHostViewModel.swift
//  NewTest
//
//  Video modülü host VM'i. SDKVideoRecorderViewModel'i sarar; yükleme olaylarını loglar.
//

import SwiftUI
import IdentifySDK

@MainActor
final class VideoRecorderHostViewModel: HostModuleViewModel {
    let sdk = SDKVideoRecorderViewModel()

    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("video_uploaded"); self?.onCompleted?() }
    }

    var hasVideo: Bool { sdk.videoData != nil }
    var uploadCompleted: Bool { sdk.uploadCompleted }
    var timeLimit: Int { Int(sdk.videoTimeLimit) }

    func deleteVideo() { log("delete_video"); sdk.deleteVideo() }
    func upload() { log("upload_video"); sdk.uploadVideo() }
}
