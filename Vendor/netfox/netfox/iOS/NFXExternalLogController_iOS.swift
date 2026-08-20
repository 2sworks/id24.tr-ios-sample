//
//  NFXExternalLogController_iOS.swift
//  netfox
//
//  Yerel fork eklentisi — host uygulamanın kendi log kaynağı için sekme.
//

#if os(iOS)

import Foundation
import UIKit

/// `NFXExternalLogSource` üzerinden beslenen kayıtları listeler.
///
/// Kaynak netfox'un dışında olduğu için (ör. WebSocket trafiği) kayıtlar bildirimle
/// değil, sekme görünürken periyodik olarak istenir.
class NFXExternalLogController_iOS: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    var source: NFXExternalLogSource?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var searchController: UISearchController!
    private var timer: Timer?

    private var entries: [NFXExternalLogEntry] = []
    private var filteredEntries: [NFXExternalLogEntry] = []
    private var searchText: String = ""
    private var autoScroll = true

    private let backgroundColor = UIColor(white: 0.11, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = source?.title ?? "Logs"
        view.backgroundColor = backgroundColor

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = backgroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(NFXExternalLogCell_iOS.self, forCellReuseIdentifier: NFXExternalLogCell_iOS.reuseIdentifier)
        view.addSubview(tableView)

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.NFXClose(), style: .plain, target: self, action: #selector(closeButtonPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed))

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Mesaj ara"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        let fetched = source?.fetch() ?? []
        // Kayıt sayısı değişmediyse listeyi yeniden çizmeye gerek yok.
        guard fetched.count != entries.count || !searchText.isEmpty else { return }

        // Panelde gösterilen her kaynak aynı sadeleştirmeden geçer.
        entries = fetched.map {
            NFXExternalLogEntry(label: $0.label, message: NFXLogRedactor.redact($0.message), tint: $0.tint)
        }
        applyFilters()
        tableView.reloadData()
        if autoScroll { scrollToLastRow() }
    }

    private func applyFilters() {
        guard !searchText.isEmpty else {
            filteredEntries = entries
            return
        }
        filteredEntries = entries.filter {
            $0.message.range(of: searchText, options: .caseInsensitive) != nil
                || $0.label.range(of: searchText, options: .caseInsensitive) != nil
        }
    }

    private func scrollToLastRow() {
        guard !filteredEntries.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: filteredEntries.count - 1, section: 0), at: .bottom, animated: false)
    }

    @objc private func closeButtonPressed() {
        NFX.sharedInstance().hide()
    }

    @objc private func shareButtonPressed() {
        guard !filteredEntries.isEmpty else { return }

        let sheet = UIAlertController(title: "Dışa aktar", message: "Biçim seçin", preferredStyle: .actionSheet)
        for format in [NFXExportFormat.csv, .json, .plainText] {
            sheet.addAction(UIAlertAction(title: format.title, style: .default) { [weak self] _ in
                self?.export(format: format)
            })
        }
        sheet.addAction(UIAlertAction(title: "Vazgeç", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
    }

    private func export(format: NFXExportFormat) {
        let title = source?.title ?? "logs"
        guard let url = NFXLogExporter.exportExternal(entries: filteredEntries, sourceTitle: title, format: format) else { return }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        activity.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        present(activity, animated: true)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: NFXExternalLogCell_iOS.reuseIdentifier, for: indexPath) as! NFXExternalLogCell_iOS
        cell.configure(with: filteredEntries[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UIPasteboard.general.string = filteredEntries[indexPath.row].message
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        autoScroll = false
    }
}

/// Etiket rozeti ve mesaj gövdesi taşıyan hücre.
class NFXExternalLogCell_iOS: UITableViewCell {

    static let reuseIdentifier = "NFXExternalLogCell"

    private let labelBadge = UILabel()
    private let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        labelBadge.font = UIFont.monospacedSystemFont(ofSize: 9, weight: .semibold)
        labelBadge.textAlignment = .center
        labelBadge.layer.cornerRadius = 3
        labelBadge.layer.masksToBounds = true
        labelBadge.setContentHuggingPriority(.required, for: .horizontal)
        labelBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        messageLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        messageLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [labelBadge, messageLabel])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            labelBadge.widthAnchor.constraint(equalToConstant: 34)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with entry: NFXExternalLogEntry) {
        labelBadge.text = entry.label
        let tint = entry.tint ?? UIColor(white: 0.5, alpha: 1.0)
        labelBadge.textColor = tint
        labelBadge.backgroundColor = tint.withAlphaComponent(0.18)
        messageLabel.text = entry.message
    }
}

#endif
