//
//  NFXConsoleController_iOS.swift
//  netfox
//
//  Yerel fork eklentisi — konsol sekmesi.
//

#if os(iOS)

import Foundation
import UIKit

/// Yakalanan konsol satırlarını canlı olarak listeler.
///
/// Xcode konsoluna benzemesi için koyu zemin ve tek aralıklı yazı tipi kullanır;
/// arama, tip süzgeci, otomatik kaydırma, temizleme ve dışa aktarma sunar.
class NFXConsoleController_iOS: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var searchController: UISearchController!
    private let autoScrollButton = UIBarButtonItem()

    private var entries: [NFXLogEntry] = []
    private var filteredEntries: [NFXLogEntry] = []
    private var searchText: String = ""
    private var selectedType: String?
    private var autoScroll = true

    /// Yenilemeyi kısıtlar: yoğun log akışında her satır için reload yapılmaz.
    private var reloadScheduled = false
    private let reloadInterval: TimeInterval = 0.25

    private let backgroundColor = UIColor(white: 0.11, alpha: 1.0)

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Console"
        view.backgroundColor = backgroundColor

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = backgroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(NFXConsoleCell_iOS.self, forCellReuseIdentifier: NFXConsoleCell_iOS.reuseIdentifier)
        view.addSubview(tableView)

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.NFXClose(), style: .plain, target: self, action: #selector(closeButtonPressed))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trashButtonPressed)),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed)),
            filterBarButtonItem()
        ]

        autoScrollButton.target = self
        autoScrollButton.action = #selector(autoScrollButtonPressed)
        updateAutoScrollButton()
        navigationItem.leftBarButtonItems = [navigationItem.leftBarButtonItem!, autoScrollButton]

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Log ara"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(logStoreDidChange),
                                               name: NFXLogStore.didAddEntryNotification,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData(scrollToBottom: autoScroll)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Data

    @objc private func logStoreDidChange() {
        guard !reloadScheduled else { return }
        reloadScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + reloadInterval) { [weak self] in
            guard let self = self else { return }
            self.reloadScheduled = false
            self.reloadData(scrollToBottom: self.autoScroll)
        }
    }

    private func reloadData(scrollToBottom: Bool) {
        entries = NFXLogStore.shared.allEntries()
        applyFilters()
        tableView.reloadData()
        if scrollToBottom { scrollToLastRow() }
    }

    private func applyFilters() {
        filteredEntries = entries.filter { entry in
            if let type = selectedType, entry.type != type { return false }
            if searchText.isEmpty { return true }
            return entry.message.range(of: searchText, options: .caseInsensitive) != nil
        }
    }

    private func scrollToLastRow() {
        guard !filteredEntries.isEmpty else { return }
        let indexPath = IndexPath(row: filteredEntries.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    // MARK: Actions

    @objc private func closeButtonPressed() {
        NFX.sharedInstance().hide()
    }

    @objc private func trashButtonPressed() {
        NFXLogStore.shared.clear()
        reloadData(scrollToBottom: false)
    }

    @objc private func shareButtonPressed() {
        guard !filteredEntries.isEmpty else { return }
        presentFormatPicker { [weak self] format in
            guard let self = self else { return }
            guard let url = NFXLogExporter.exportConsole(entries: self.filteredEntries, format: format) else { return }
            self.presentShareSheet(for: url)
        }
    }

    /// Dışa aktarma biçimini sorar. Dosya olarak paylaşıldığı için kayıt e-posta
    /// ya da mesajlaşma uygulamalarına ek olarak gidebilir.
    private func presentFormatPicker(completion: @escaping (NFXExportFormat) -> Void) {
        let sheet = UIAlertController(title: "Dışa aktar", message: "Biçim seçin", preferredStyle: .actionSheet)
        for format in [NFXExportFormat.csv, .json, .plainText] {
            sheet.addAction(UIAlertAction(title: format.title, style: .default) { _ in completion(format) })
        }
        sheet.addAction(UIAlertAction(title: "Vazgeç", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        present(sheet, animated: true)
    }

    private func presentShareSheet(for url: URL) {
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        // Paylaşım bittiğinde geçici dosya bırakılmaz.
        activity.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        present(activity, animated: true)
    }

    @objc private func autoScrollButtonPressed() {
        autoScroll.toggle()
        updateAutoScrollButton()
        if autoScroll { scrollToLastRow() }
    }

    private func updateAutoScrollButton() {
        autoScrollButton.title = autoScroll ? "Takip: açık" : "Takip: kapalı"
    }

    private func filterBarButtonItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(title: "Tür", style: .plain, target: nil, action: nil)
        item.menu = UIMenu(title: "Tür", children: menuActions())
        return item
    }

    private func menuActions() -> [UIAction] {
        var types = Set(NFXLogStore.shared.allEntries().map { $0.type })
        types.insert("console")

        var actions: [UIAction] = [
            UIAction(title: "Tümü", state: selectedType == nil ? .on : .off) { [weak self] _ in
                self?.selectType(nil)
            }
        ]
        for type in types.sorted() {
            actions.append(UIAction(title: type, state: selectedType == type ? .on : .off) { [weak self] _ in
                self?.selectType(type)
            })
        }
        return actions
    }

    private func selectType(_ type: String?) {
        selectedType = type
        navigationItem.rightBarButtonItems?.last?.menu = UIMenu(title: "Tür", children: menuActions())
        reloadData(scrollToBottom: autoScroll)
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        applyFilters()
        tableView.reloadData()
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NFXConsoleCell_iOS.reuseIdentifier, for: indexPath) as! NFXConsoleCell_iOS
        cell.configure(with: filteredEntries[indexPath.row])
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let entry = filteredEntries[indexPath.row]
        let detail = NFXConsoleDetailController_iOS()
        detail.entry = entry
        navigationController?.pushViewController(detail, animated: true)
    }

    /// Kullanıcı listeyi elle kaydırdığında takip kapanır; en dibe dönerse açılır.
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard autoScroll else { return }
        autoScroll = false
        updateAutoScrollButton()
    }
}

/// Tek bir konsol satırı hücresi.
class NFXConsoleCell_iOS: UITableViewCell {

    static let reuseIdentifier = "NFXConsoleCell"

    private let timeLabel = UILabel()
    private let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = UIColor(white: 0.55, alpha: 1.0)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        messageLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [timeLabel, messageLabel])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with entry: NFXLogEntry) {
        timeLabel.text = entry.timeText
        messageLabel.text = entry.message
        messageLabel.textColor = NFXConsoleCell_iOS.color(for: entry)
    }

    /// Satırın türüne ve içeriğine göre renk. Hata ve uyarı satırları ayrışsın diye.
    private static func color(for entry: NFXLogEntry) -> UIColor {
        let lowercased = entry.message.lowercased()
        if lowercased.contains("error") || lowercased.contains("hata") || lowercased.contains("failed") {
            return UIColor(red: 1.0, green: 0.45, blue: 0.42, alpha: 1.0)
        }
        switch entry.type {
        case "socket":
            return UIColor(red: 0.45, green: 0.78, blue: 1.0, alpha: 1.0)
        case "nfc":
            return UIColor(red: 0.72, green: 0.62, blue: 1.0, alpha: 1.0)
        case "console":
            return UIColor(white: 0.78, alpha: 1.0)
        default:
            return UIColor(red: 0.62, green: 0.92, blue: 0.62, alpha: 1.0)
        }
    }
}

/// Uzun satırların tamamını gösterir ve panoya kopyalamayı sağlar.
class NFXConsoleDetailController_iOS: UIViewController {

    var entry: NFXLogEntry?

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = entry?.timeText
        view.backgroundColor = UIColor(white: 0.11, alpha: 1.0)

        textView.frame = view.bounds
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textColor = UIColor(white: 0.9, alpha: 1.0)
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.text = entry?.exportText
        view.addSubview(textView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Kopyala", style: .plain, target: self, action: #selector(copyButtonPressed))
    }

    @objc private func copyButtonPressed() {
        UIPasteboard.general.string = entry?.exportText
    }
}

#endif
