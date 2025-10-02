//
//  SDKNfcViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 25.10.2022.
//

import UIKit
import IdentifySDK

class SDKNfcViewController: SDKBaseViewController {

    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var informationStackView: UIStackView!
    @IBOutlet weak var startNFCActBtn: IdentifyButton!
    @IBOutlet weak var errorStackView: UIStackView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var errSerialNo: UITextField!
    @IBOutlet weak var errBirthday: UITextField!
    @IBOutlet weak var errValidDate: UITextField!
    @IBOutlet weak var errSaveBtn: IdentifyButton!
    @IBOutlet weak var dateSelector: UIDatePicker!
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var dateStackHeight: NSLayoutConstraint!
    var dateStackDefaultConst = 232.0
    var pickerIsShowing = true
    var isBirthday = false
    @IBOutlet weak var errorTitleLbl: UILabel!
    @IBOutlet weak var errorSubTitleLbl: UILabel!
    @IBOutlet weak var serialNoLbl: UILabel!
    @IBOutlet weak var birtdateLbl: UILabel!
    @IBOutlet weak var expDateLbl: UILabel!
    
    var showOnlyEditScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if manager.selectedCardType == .oldSchool {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .coreNfcDeviceError), attachTo: self.view) {
                    self.goToNextPage()
                }
            })
        }
        setupUI()
        setupNFCMessages()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.showErrorScreen(needShow: false)
        self.setupUI()
    }
    
    func goToNextPage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.manager.getNextModule { nextVC in
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        })
    }
    
    func setupUI() {
        self.errorTitleLbl.text = self.translate(text: .nfcKeyErrTitle)
        self.errorSubTitleLbl.text = self.translate(text: .nfcKeyErrSubTitle)
        self.serialNoLbl.text = self.translate(text: .nfcSerialNo)
        self.birtdateLbl.text = self.translate(text: .nfcBirthDate)
        self.expDateLbl.text = self.translate(text: .nfcExpDate)
        self.infoLbl.text = self.translate(text: .popNFC)
        self.dateStackHeight.constant = 0
        startNFCActBtn.setTitle(self.translate(text: .nfcStart), for: .normal)
        startNFCActBtn.type = .submit
        startNFCActBtn.onTap = {
            self.startNFC()
        }
        startNFCActBtn.populate()
        
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.backgroundColor = IdentifyTheme.submitBlueColor
        datePicker.tintColor = IdentifyTheme.lightWhiteColor
        errSaveBtn.type = .submit
        errSaveBtn.setTitle(self.translate(text: .coreUpdate), for: .normal)
        errSaveBtn.onTap = {
            let data = BackIdInfo()
            data.idBirthDateMRZ = self.errBirthday.text?.toMrzDate() ?? ""
            data.idValidDateMRZ = self.errValidDate.text?.toMrzDate() ?? ""
            data.idDocumentNumberMRZ = self.errSerialNo.text ?? ""
            self.manager.sdkBackInfo = data
            self.startNFC()
        }
        errSaveBtn.populate()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.listenBirthday))
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.listenValidDate))

        self.errBirthday.addGestureRecognizer(tap)
        self.errValidDate.addGestureRecognizer(tap2)
        
        if showOnlyEditScreen {
            errorStackView.isHidden = false
            startNFCActBtn.isHidden = true
            let cachedKeys = self.manager.sdkBackInfo
            self.errSerialNo.text = cachedKeys.idDocumentNumberMRZ
            self.errBirthday.text = cachedKeys.idBirthDateMRZ?.mrzToNormalDate()
            self.errValidDate.text = cachedKeys.idValidDateMRZ?.mrzToNormalDate()
            self.infoLbl.isHidden = true
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap() {
        view.endEditing(true)
    }
    
    private func showHidePickerStack() {
        if pickerIsShowing {
            UIView.animate(withDuration: 0.3, delay: 0) {
                self.dateStackHeight.constant = self.dateStackDefaultConst
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0) {
                self.dateStackHeight.constant = 0
                self.view.layoutIfNeeded()
            }
        }
        self.pickerIsShowing = !self.pickerIsShowing
    }
    
    @objc func listenBirthday() {
        self.isBirthday = true
        showHidePickerStack()
        openSelectedDate()
    }
    
    @objc func listenValidDate() {
        self.isBirthday = false
        showHidePickerStack()
        openSelectedDate()
    }
    
    func openSelectedDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        var selectedDate = formatter.date(from: self.errBirthday.text?.mrzToNormalDate() ?? "")

        if isBirthday {
            selectedDate = formatter.date(from: self.errBirthday.text ?? "")
        } else {
            selectedDate = formatter.date(from: self.errValidDate.text ?? "")
        }
        datePicker.date = selectedDate ?? Date()
    }
    
    func setupNFCMessages() {
        let customMessageHandler : ((NFCViewDisplayMessage) -> String)? = { displayMessage in
            switch displayMessage {
                case .requestPresentPassport:
                    return "Lütfen belgenizi ön kameranın üzerine getirin ve oynatmadan bekleyin"
                case .authenticatingWithPassport(let progress):
                    let progressString = self.handleProgress(percentualProgress: progress)
                    return "Kimliğiniz doğrulanıyor.....\n\n\(progressString)"
                case .readingDataGroupProgress(let dataGroup, let progress):
                    let progressString = self.handleProgress(percentualProgress: progress)
                    return "Veriler okunuyor \(dataGroup).....\n\n\(progressString)"
                case .error(let tagError):
                    switch tagError {
                        case NFCPassportReaderError.TagNotValid:
                            return "Tag geçerli değil."
                        case NFCPassportReaderError.MoreThanOneTagFound:
                            return "Birden fazla nesne bulundu, lütfen tek nesne ile deneyin."
                        case NFCPassportReaderError.ConnectionError:
                            return "Bağlantı hatası, tekrar deneyin"
                        case NFCPassportReaderError.InvalidMRZKey:
                            return "MRZ Key doğrulanamadı"
                        case NFCPassportReaderError.ResponseError(let description, let sw1, let sw2):
                            return "Üzgünüz, okuma sırasında hatalar alındı. \(description) - (0x\(sw1), 0x\(sw2)"
                        default:
                            return "Okuma sırasında hata alındı, lütfen tekrar dene"
                }
            case .successfulRead:
                return "Belge başarıyla okundu"
            }
        }
        self.manager.nfcMsgHandler = customMessageHandler
    }
    
    func handleProgress(percentualProgress: Int) -> String {
        let p = (percentualProgress/20)
        let full = String(repeating: "🟢 ", count: p)
        let empty = String(repeating: "⚪️ ", count: 5-p)
        return "\(full)\(empty)"
    }
    
    func startNFC() {
        self.showLoader()
        self.manager.startNFC { idCard, identStatus, webResponse, err in
//            print(idCard?.asDictionary()) // kimlik kartının içindeki veriler
            
            if self.showOnlyEditScreen {
                self.hideLoader()
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            } else {
                self.hideLoader()
                if webResponse.result == false {
                    if webResponse.msg == "MAX_ERR_COUNT" {
                        self.goToNextPage()
                    } else {
                        if let errMsg = webResponse.msg, errMsg != "" {
                            self.oneButtonAlertShow(message:errMsg, title1: "Hata") {
                                return
                            }
                        }
                    }
                } else if webResponse.result == true && webResponse.data?.comparison == false {
                    let alertMsg = self.translate(text: .activeNfcWarn)
                    let alertExpMsg = self.translate(text: .activeNfcExit)
                    if self.manager.nfcComparisonCount == self.manager.tryedNfcComparisonCount {
                        self.oneButtonAlertShow(message: alertExpMsg, title1: "Tamam") {
                            self.closeSDK()
                        }
                    } else {
                        self.oneButtonAlertShow(message: alertMsg, title1: "Tamam") {
                            self.manager.tryedNfcComparisonCount += 1
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                } else if webResponse.result == true && webResponse.data?.comparison == true {
                    self.manager.tryedNfcComparisonCount = 1 // resetliyoruz
                    self.goToNextPage()
                }
                
                if let error = err {
                    DispatchQueue.main.async {
                        self.showLoader()
                        print(err?.localizedDescription)
                        if self.showOnlyEditScreen {
                            DispatchQueue.main.async {
                                self.hideLoader()
                                self.dismiss(animated: true)
                            }
                        }
                        self.showErrorScreen(needShow: true)
                    }
                }
            }
        }
    }
    
    private func showErrorScreen(needShow:Bool) {
        DispatchQueue.main.async {
            self.hideLoader()
            self.startNFCActBtn.isHidden = true
            self.startNFCActBtn.populate()
            self.informationStackView.isHidden = needShow
            self.errorStackView.isHidden = !needShow
            self.startNFCActBtn.isHidden = needShow
            if self.manager.useKpsData {
                self.errSerialNo.text = self.manager.mrzDocNo
                self.errBirthday.text = self.manager.mrzBirthDay.mrzToNormalDate()
                self.errValidDate.text = self.manager.mrzValidDate.mrzToNormalDate()
            } else {
                let cachedKeys = self.manager.sdkBackInfo
                self.errSerialNo.text = cachedKeys.idDocumentNumberMRZ
                self.errBirthday.text = cachedKeys.idBirthDateMRZ?.mrzToNormalDate()
                self.errValidDate.text = cachedKeys.idValidDateMRZ?.mrzToNormalDate()
            }
            
        }
    }
    
    @IBAction func doneAct(_ sender: Any) {
        self.showHidePickerStack()
    }
    
    @IBAction func datePickerChanged(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.locale = Locale(identifier: "tr")
        let strDate = dateFormatter.string(from: datePicker.date)
        if isBirthday {
            self.errBirthday.text = strDate
        } else {
            self.errValidDate.text = strDate
        }
    }
}
