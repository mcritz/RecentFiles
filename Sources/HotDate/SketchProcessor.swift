//
//  SketchProcessor.swift
//  HotDate
//
//  Created by Critz, Michael on 10/17/19.
//

import Foundation

class SketchProcessor {
    // TODO: Not die silently
    /// Creates a task to convert Sketch file
    /// - Parameter url: source file URL
    /// - Parameter destinationFolder: top folder where  converted artboards are stored in a sub-folder  as PNGs.
    func convertSketch(file url: URL, destinationFolder: URL, completion: @escaping (Bool) -> ()) {
        let subFolderName = url.deletingPathExtension().lastPathComponent
        let subFolderURL = destinationFolder.appendingPathComponent(subFolderName)
        do {
            try FileManager
                .default
                .createDirectory(at: subFolderURL,
                                 withIntermediateDirectories: false,
                                 attributes: [:])
        } catch {
            print("Subfolder \(subFolderName) already exists")
        }
        let task = Process()
        task.launchPath = "/Applications/Sketch.app/Contents/Resources/sketchtool/bin/sketchtool"
        task.arguments = [
            "export",
            "artboards",
            url.path,
            "--output=\(subFolderURL.path)",
            "--formats=png,pdf",
            "--scales=1"
        ]
        task.terminationHandler = { completedTask -> Void in
            print("Termionated as \(completedTask.terminationStatus)")
        }
        task.launch()
        task.waitUntilExit()
        print("conversion stopped")
        completion(task.terminationStatus == 0) // Terminates as complete
    }
}
