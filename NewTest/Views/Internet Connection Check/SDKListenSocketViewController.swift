//
//  SDKListenSocketViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 22.11.2022.
//

import UIKit

protocol SDKNoConnectionDelegate: AnyObject {
    func reconnectCompleted()
    func reconnectCompletedWithStatus(isWaitingRoom: Bool, statusType: String?)
}

class SDKListenSocketViewController: SDKBaseViewController {

    @IBOutlet weak var reConnectBtn: UIButton!
    weak var delegate: SDKNoConnectionDelegate?

    private var isReconnecting = false
    /// Kullanıcı hiç dokunmasa da denenen otomatik yeniden bağlanma turu.
    private var autoRetryTimer: Timer?
    private var autoRetryCount = 0
    private let autoRetryMaxCount = 6
    private let autoRetryInterval: TimeInterval = 5

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleReachabilityChanged(_:)),
                                               name: .reachabilityChanged,
                                               object: nil)

        startAutoRetry()
    }

    /// ⚠️ `socket.onDisconnect` **tek slotlu**. Base sınıf her `viewWillAppear`'da bu
    /// slotu kendi üzerine yazıyor; bu ekran da yazsaydı kapanıp dealloc olduğunda slot
    /// ölü bir VC'yi işaret eder halde kalır ve sonraki kopmalarda yeniden bağlanma
    /// ekranı hiç açılmazdı. Bu ekranın zaten kendini açmaya ihtiyacı yok.
    override var listensToSocketDisconnect: Bool { false }

    private func setupUI() {
        reConnectBtn.setTitle(self.translate(text: .coreReConnect), for: .normal)
        reConnectBtn.cornerRadius = 3
        reConnectBtn.backgroundColor = IdentifyTheme.whiteColor
        reConnectBtn.setTitleColor(IdentifyTheme.submitBlueColor, for: .normal)
        reConnectBtn.dropShadow(color: .black, opacity: 0.3, offSet: CGSize(width: -1, height: 1), radius: 9, scale: true)
        reConnectBtn.addTarget(self, action: #selector(tapButton), for: .touchUpInside)

        // ⚠️ Buton reachability'ye göre KİLİTLENMİYOR. WiFi kapanıp hücresel devreye
        // girerken SCNetworkReachability birkaç saniye `.unavailable` raporluyor; bu ekran
        // kopmadan ~1 sn sonra açıldığı için o pencereye denk gelip kalıcı olarak kapalı
        // kalıyor, kullanıcı toparlanmayı sağlayacak tek eylemi yapamıyordu.
        // İnternet gerçekten yoksa deneme zaten başarısız olur ve buton geri açılır.
        if SDKReachabilityHelper.shared.reachability.connection == .unavailable {
            reConnectBtn.setTitle(self.translate(text: .coreNoInternet), for: .normal)
        }
    }

    /// Kullanıcı dokunmasa bile belirli aralıklarla yeniden bağlanmayı dener.
    private func startAutoRetry() {
        autoRetryTimer?.invalidate()
        autoRetryTimer = Timer.scheduledTimer(withTimeInterval: autoRetryInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            guard self.autoRetryCount < self.autoRetryMaxCount else {
                print("reconnect: otomatik deneme sınırına ulaşıldı, kullanıcı elle deneyebilir")
                timer.invalidate()
                self.autoRetryTimer = nil
                return
            }
            guard !self.isReconnecting else { return }
            self.autoRetryCount += 1
            print("reconnect: otomatik deneme \(self.autoRetryCount)/\(self.autoRetryMaxCount)")
            self.tapButton()
        }
    }

    private func stopAutoRetry() {
        autoRetryTimer?.invalidate()
        autoRetryTimer = nil
    }
    
    @objc func tapButton() {
        // İkinci dokunuşu veya reachability kaynaklı paralel tetiklenmeyi engeller
        guard !isReconnecting else { return }

        isReconnecting = true
        reConnectBtn.setTitle(self.translate(text: .coreReconnecting), for: .normal)
        toggleButton(disabled: true)

        if manager.socket.isConnected {
            // Bağlı ama cevap vermiyorsa önce kes, 3s sonra yeniden bağlan.
            // Bu süre boyunca isReconnecting = true olduğu için tekrar tetiklenemez.
            manager.disconnectSocket(reason: .reconnectCycle) // 4104 — sunucu logunda sebep görünür
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self.reconnectSocket()
            })
        } else {
            reconnectSocket()
        }
    }

    func reconnectSocket() {
        self.manager.reconnectToSocket(callback: { [weak self] socket in
            guard let self = self else { return }
            // Callback dönünce (başarılı veya başarısız) flag'i serbest bırak
            self.isReconnecting = false
            if socket.isConnected {
                self.stopAutoRetry()
                self.delegate?.reconnectCompleted()
                print("tekrar bağlantı kuruldu")
                self.dismiss(animated: true)
            } else {
                // Bağlantı kurulamadıysa butonu tekrar aktif et, kullanıcı tekrar deneyebilir
                self.toggleButton(disabled: false)
            }
        }, statusCallback: { [weak self] statusSummary in
            guard let self = self else { return }
            // statusSummary.id == -3 → bekleme odasına dönülüyor
            let isWaitingRoom = statusSummary?.id == -3
            DispatchQueue.main.async {
                self.delegate?.reconnectCompletedWithStatus(isWaitingRoom: isWaitingRoom, statusType: statusSummary?.type)
            }
        })
    }
    
    func toggleButton(disabled: Bool) {
        if disabled {
            reConnectBtn.alpha = 0.2
            reConnectBtn.isUserInteractionEnabled = false
        } else {
            reConnectBtn.alpha = 1.0
            reConnectBtn.isUserInteractionEnabled = true
        }
    }

    deinit {
        autoRetryTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
    }

    @objc private func handleReachabilityChanged(_ note: Notification) {
        guard let reachability = note.object as? Reachability else { return }
        DispatchQueue.main.async { [weak self] in
            switch reachability.connection {
            case .wifi, .cellular:
                // İnternet geri geldi; ama reconnect zaten devam ediyorsa butonu
                // açma — aksi takdirde kullanıcı tekrar tıklayıp çift girişim olur.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    guard self?.isReconnecting == false else { return }
                    self?.reConnectBtn.setTitle(self?.translate(text: .coreReConnect), for: .normal)
                    self?.toggleButton(disabled: false)
                })
            case .unavailable:
                // Yalnızca metni değiştir: buton kilitlenmiyor (bkz. setupUI'daki not).
                guard self?.isReconnecting == false else { return }
                self?.reConnectBtn.setTitle(self?.translate(text: .coreNoInternet), for: .normal)
                self?.toggleButton(disabled: false)
            }
        }
    }

}
