//
//  SketchFile.swift
//  Firehose
//
//  Created by Critz, Michael on 11/6/19.
//

import Foundation

protocol CZFileRepresentable {
    var sourceURL: URL { get }
    var title: String { get }
    var fileName: String { get }
    var modificationDate: Date { get }
    var childCount: Int { get }
}

struct CZFile: CZFileRepresentable, Codable {
    var sourceURL: URL
    var title: String
    var fileName: String
    var modificationDate: Date
    var childCount = 0
    
    init(with url: URL, modified: Date = Date()) {
        sourceURL = url
        fileName = url.lastPathComponent
        title = sourceURL.deletingPathExtension().lastPathComponent
        modificationDate = modified
    }
}

struct SketchFile: CZFileRepresentable, Codable {
    var sourceURL: URL
    var title: String
    var fileName: String
    var modificationDate: Date
    var children: [SketchPage]?
    var childCount: Int { children?.count ?? 0 }
}

struct SketchPage: CZFileRepresentable, Codable {
    let parent: SketchFile
    var sourceURL: URL { parent.sourceURL }
    var modificationDate: Date { parent.modificationDate }
    var childCount: Int { 0 }
    let uuid: UUID
    let title: String
    var fileName: String
}

