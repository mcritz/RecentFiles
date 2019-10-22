//
//  SketchProcessor.swift
//  HotDate
//
//  Created by Critz, Michael on 10/17/19.
//

import Foundation

class SketchProcessor {
    
    /// Creates a task to convert Sketch file
    /// - Parameter url: source file URL
    /// - Parameter destinationFolder: folder where  converted artboards are stored as PNGs
    func convertSketch(file url: URL, destinationFolder: URL) {
        let task = Process()
        task.launchPath = "/Applications/Sketch.app/Contents/Resources/sketchtool/bin/sketchtool"
//        task.launchPath = "/Users/mcritz/Applications/sketch.sh"
        task.arguments = [
            "export",
            "artboards",
            url.path,
            "--output=~/Desktop"
        ]
        task.terminationHandler = { completedTask -> Void in
            print("Termionated as \(completedTask.terminationStatus)")
        }
        task.launch()
    }
}

let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
let fileURL = desktopURL.appendingPathComponent("PS_Store_SortFilter.sketch")
print(fileURL.path)
print(fileURL.absoluteString)
print(fileURL.absoluteURL)

SketchProcessor().convertSketch(file: fileURL, destinationFolder: desktopURL)

