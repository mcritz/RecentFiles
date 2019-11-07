//
//  ViewController.swift
//  Firehose
//
//  Created by Critz, Michael on 11/4/19.
//

import AppKit
import PDFKit

// MARK: - Window & Toolbar
class FireHoseWindowController: NSWindowController {
    @IBOutlet weak var refreshToolbarItem: NSToolbarItem!
    @IBOutlet weak var firehoseToolbar: NSToolbar!
    @IBAction func refreshAction(_ sender: Any) {
    }
}

// MARK: - SplitView
class FirehoseSplitViewController: NSSplitViewController, FirehoseSourceViewDelegate {
    func handle(selected url: URL) {
        print(url.path)
        guard let fhDetailViewController = splitViewItems[1].viewController as? FireHoseViewController else { return }
        if let pdfDoc = PDFDocument(url: url) {
            fhDetailViewController.pdfView.document = pdfDoc
            fhDetailViewController.pdfView.autoScales = true
        }
    }
    override func viewWillAppear() {
        if let fhSourceViewController = splitViewItems[0].viewController as? FirehoseSourceView {
            fhSourceViewController.delegate = self
        }
    }
}

// MARK: - SourceView
protocol FirehoseSourceViewDelegate {
    func handle(selected url: URL)
}

class FirehoseSourceView: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var delegate: FirehoseSourceViewDelegate?
    let searchURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    let fun = FileUpdateNotifier(searchURL: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"))
    
    var outlineItems: [CZFileRepresentable]? {
        didSet {
            print("didSet with: \(String(describing: outlineItems?.count)) outlineItems")
            outlineView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        outlineView.delegate = self
        outlineView.dataSource = self
        loadRecents()
    }
    
    func loadRecents() {
        fun.recentFiles(at: [searchURL],
                        completion: { urls in
            print("done \(urls.count)")
            outlineItems = urls.map({ url -> CZFileRepresentable in
                return CZFile(with: url)
            })
        })
    }
    
    func outlineView(_ outlineView: NSOutlineView,
                     numberOfChildrenOfItem item: Any?) -> Int {
        outlineItems?.count ?? 1
    }
    
    func outlineView(_ outlineView: NSOutlineView,
                     child index: Int,
                     ofItem item: Any?) -> Any {
        outlineItems?[index] ?? "Whoops"
    }
    
    func outlineView(_ outlineView: NSOutlineView,
                     isItemExpandable item: Any) -> Bool {
        if let fileItem = item as? CZFileRepresentable {
            return fileItem.childCount > 0
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView,
                     viewFor tableColumn: NSTableColumn?,
                     item: Any) -> NSView? {
        var view: NSTableCellView?
        if let fileItem = item as? CZFile {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView
            view?.textField?.stringValue = fileItem.title
        }
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView else { return }
        let index = outlineView.selectedRow
        if let file = outlineItems?[index] {
            delegate?.handle(selected: file.sourceURL)
        }
    }

}

// MARK: - ViewController
class FireHoseViewController: NSViewController {
    @IBOutlet weak var pdfView: PDFView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = Bundle.main.url(forResource: "TileComponents", withExtension: "pdf") {
            if let doc = PDFDocument(url: url) {
                pdfView.document = doc
                pdfView.autoScales = true
            }
        }
    }
}
