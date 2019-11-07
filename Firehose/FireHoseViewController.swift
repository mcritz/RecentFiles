//
//  ViewController.swift
//  Firehose
//
//  Created by Critz, Michael on 11/4/19.
//

import AppKit
import PDFKit


// MARK: - Toolbar
class FireHoseWindowController: NSWindowController {
    @IBOutlet weak var refreshToolbarItem: NSToolbarItem!
    @IBOutlet weak var firehoseToolbar: NSToolbar!
    @IBAction func refreshAction(_ sender: Any) {
        if let fhvc = viewController as? FireHoseViewController {
            fhvc.loadRecents()
        }
        print("refresh: \(String(describing: viewController))")
    }
    var viewController: NSViewController {
        get {
            return self.window!.contentViewController!
        }
    }
}

// MARK: - ViewController

class FireHoseViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var pdfView: PDFView!
    
    var outlineItems: [CZFileRepresentable]? {
        didSet {
            print("didSet with: \(String(describing: outlineItems?.count)) outlineItems")
            outlineView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = Bundle.main.url(forResource: "TileComponents", withExtension: "pdf") {
            if let doc = PDFDocument(url: url) {
                pdfView.document = doc
                pdfView.autoScales = true
            }
        }
        loadRecents()
        outlineView.delegate = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension FireHoseViewController: NSOutlineViewDataSource {
    func loadRecents() {
        let searchURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let fun = FileUpdateNotifier(searchURL: searchURL)
        fun.recentFiles(at: [searchURL], completion: { urls in
            print("done \(urls.count)")
            outlineItems = urls.map({ url -> CZFileRepresentable in
                return CZFile(with: url)
            })
        })
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        outlineItems?.count ?? 1
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        outlineItems?[index] ?? "Whoops"
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let fileItem = item as? CZFileRepresentable {
            return fileItem.childCount > 0
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
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
            guard let pdfdoc = PDFDocument(url: file.sourceURL) else { return }
            self.pdfView.document = pdfdoc
            self.pdfView.autoScales = true
        }
    }
}

extension FireHoseViewController: NSOutlineViewDelegate {
}
