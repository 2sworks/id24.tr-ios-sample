//
//  AddressConfirmViewModel.swift
//  NewTest
//
//  SDK: uploadAddressInfo, uploadAddressInfoWithPdf, maxAddressPDFFileSize
//

import Foundation
import UIKit
import PDFKit
import IdentifySDK

@MainActor
final class AddressConfirmViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published var addressText: String = ""
    @Published var docPhoto: UIImage? = nil
    @Published var pdfData: Data? = nil

    // Picker / sheet triggers
    @Published var showDocumentOptions: Bool = false
    @Published var showScanner: Bool = false
    @Published var showGallery: Bool = false
    @Published var showPDFPicker: Bool = false

    var isAddressValid: Bool { addressText.count >= 10 }

    var canSubmit: Bool {
        isAddressValid && (docPhoto != nil || pdfData != nil)
    }

    var maxPDFSizeMB: Int { manager.maxAddressPDFFileSize }

    // MARK: - Document Options

    func openScanner() {
        showDocumentOptions = false
        showScanner = true
    }

    func openGallery() {
        showDocumentOptions = false
        showGallery = true
    }

    func openPDFPicker() {
        showDocumentOptions = false
        showPDFPicker = true
    }

    // MARK: - Dokuman Secildi

    func photoSelected(_ image: UIImage) {
        docPhoto = image
        pdfData = nil
        errorMessage = nil
    }

    func pdfSelectedFromURL(_ url: URL) {
        guard let data = try? Data(contentsOf: url) else {
            errorMessage = "Dosya okunamadı"
            return
        }
        pdfSelected(data, preview: renderPDFFirstPage(url))
    }

    func pdfSelected(_ data: Data, preview: UIImage? = nil) {
        let maxBytes = maxPDFSizeMB * 1024 * 1024
        if data.count > maxBytes {
            let sizeMB = data.count / (1024 * 1024)
            errorMessage = "PDF maksimum \(maxPDFSizeMB) MB olabilir (\(sizeMB) MB seçildi)"
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
                        self.errorMessage = "PDF yükleme başarısız"
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
                        self.errorMessage = "Yükleme başarısız"
                    }
                }
            }
        }
    }

    // MARK: - PDF Preview

    private func renderPDFFirstPage(_ url: URL) -> UIImage? {
        guard let doc = PDFDocument(url: url),
              let page = doc.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: bounds.size))
            ctx.cgContext.translateBy(x: 0, y: bounds.size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}
