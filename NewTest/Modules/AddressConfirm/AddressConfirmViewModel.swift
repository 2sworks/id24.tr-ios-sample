//
//  AddressConfirmViewModel.swift
//  NewTest
//
//  Adres dogrulama ekraninin ViewModel'i.
//  SDK: uploadAddressInfo, uploadAddressInfoWithPdf, maxAddressPDFFileSize
//

import Foundation
import UIKit
import IdentifySDK

@MainActor
final class AddressConfirmViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published var addressText: String = ""
    @Published var docPhoto: UIImage? = nil
    @Published var showPDFOption: Bool = false
    @Published var pdfData: Data? = nil

    var isAddressValid: Bool { addressText.count >= 10 }

    var canSubmit: Bool {
        isAddressValid && (docPhoto != nil || pdfData != nil)
    }

    var maxPDFSizeMB: Int { manager.maxAddressPDFFileSize }

    // MARK: - Dokuman Secildi

    func photoSelected(_ image: UIImage) {
        docPhoto = image
        pdfData = nil
        errorMessage = nil
    }

    func pdfSelected(_ data: Data, preview: UIImage? = nil) {
        let sizeMB = data.count / (1024 * 1024)
        if sizeMB > maxPDFSizeMB {
            errorMessage = "PDF max \(maxPDFSizeMB) MB olabilir (\(sizeMB) MB secildi)"
            return
        }
        pdfData = data
        if let preview { docPhoto = preview }
        errorMessage = nil
    }

    // MARK: - Yukleme

    func submit(appState: AppStateViewModel) {
        isLoading = true
        errorMessage = nil

        if let pdf = pdfData {
            manager.uploadAddressInfoWithPdf(pdfData: pdf, addressText: addressText) { [weak self] success, err in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    if let err, (err.errorMessages ?? "").isEmpty == false {
                        self.errorMessage = err.errorMessages
                    } else if success {
                        appState.advanceToNextModule()
                    } else {
                        self.errorMessage = "PDF yukleme basarisiz"
                    }
                }
            }
        } else if let photo = docPhoto {
            manager.uploadAddressInfo(invoicePhoto: photo, addressText: addressText) { [weak self] success, err in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    if let err, (err.errorMessages ?? "").isEmpty == false {
                        self.errorMessage = err.errorMessages
                    } else if success {
                        appState.advanceToNextModule()
                    } else {
                        self.errorMessage = "Yukleme basarisiz"
                    }
                }
            }
        }
    }
}
