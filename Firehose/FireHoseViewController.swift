//
//  ViewController.swift
//  Firehose
//
//  Created by Critz, Michael on 11/4/19.
//

import AppKit
import PDFKit

class FireHoseViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var pdfView: PDFView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = Bundle.main.url(forResource: "TileComponents", withExtension: "pdf") {
            if let doc = PDFDocument(url: url) {
                pdfView.document = doc
                pdfView.autoScales = true
            }
        }
        loadRecents()
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
        fun.recentFiles(at: [searchURL], completion: {_ in
            print("done")
        })
    }
}
