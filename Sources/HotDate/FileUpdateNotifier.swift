//
//  FileUpdateNotifier.swift
//  Updates
//
//  Created by Critz, Michael on 9/26/19.
//  Copyright © 2019 pixel.science. All rights reserved.
//

import Foundation
import ConsoleKit

class FileUpdateNotifier {
    
    let term: Terminal
    
    var fileURLs: [URL]
    var recencyMinutes: Double
    
    private var searchedCount: Int = 0
    
    /// Creates a new FUN instance using a search URL and the time in minutes to search
    /// - Parameter searchURL: file url to search for
    /// - Parameter minutes: time in minutes. Default is 24 hours.
    init(searchURL: URL, within minutes: Double = 1_440) {
        fileURLs = [searchURL]
        recencyMinutes = minutes * 60 // seconds
        self.term = Terminal()
    }
    
// MARK: - Intented Entry Point
    /// **Intended entry point**
    /// Gets recent files at a file URL
    /// - Parameter urls: local file URL to search
    /// - Parameter completion: handler for files found
    func recentFiles(at urls: [URL], completion: ([URL]) throws -> Void) {
        let activityBar = term.loadingBar(title: "Searching")
        do {
            activityBar.start()
            try completion(contents(of: urls))
        } catch {
            term.error(error.localizedDescription, newLine: true)
            activityBar.fail()
        }
        activityBar.succeed()
    }

    // MARK: - Ineternals
    
    /// Gets sub-URLs of a file URL with approriate file masks
    /// - Parameter searchURL: file URL to search
    private func subURLs(of searchURL: URL) -> [URL] {
        return try! FileManager
        .default
        .contentsOfDirectory(at: searchURL,
                             includingPropertiesForKeys: [
                                URLResourceKey.contentModificationDateKey,
                                URLResourceKey.addedToDirectoryDateKey,
                                URLResourceKey.creationDateKey,
                                URLResourceKey.isDirectoryKey,
                                URLResourceKey.nameKey
                                ],
                             options: [
                                FileManager.DirectoryEnumerationOptions.skipsPackageDescendants,
                                FileManager.DirectoryEnumerationOptions.skipsHiddenFiles,
                            ]
        )
    }
    
    
    /// Determines if a file is within the class’ expected recent minutes
    /// - Parameter url: file URL to search
    private func isRecentFile(at url: URL) -> Bool {
        var fileAttributes: [FileAttributeKey : Any]
        do {
            fileAttributes = try FileManager.default.attributesOfItem(atPath: url.relativePath)
        } catch {
            return false
        }
        let maybeCreationDate = fileAttributes[FileAttributeKey.creationDate] as? Date
        guard let creationDate: Date = maybeCreationDate else { return false }
        if creationDate.timeIntervalSince(Date()) > -(recencyMinutes) {
            term.info("Matched:\(String(describing: url.lastPathComponent))", newLine: true)
            return true
        }
        return false
    }
    
    /// Returns files, and excludes folders
    /// - Parameter urls: file URL to search in
    private func contents(of urls: [URL]) -> [URL] {
        searchedCount += urls.count
        var resultURLs = urls
        _ = urls.filter { url in
            if url.hasDirectoryPath {
                resultURLs.removeAll { directoryURL -> Bool in
                    directoryURL == url
                }
                resultURLs.append(contentsOf: contents(of: subURLs(of: url)))
                return false
            }
            return true
        }
        return resultURLs.filter { isRecentFile(at: $0) }
    }
    
}
