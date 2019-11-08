//
//  SketchProcessor.swift
//  HotDate
//
//  Created by Critz, Michael on 10/17/19.
//

import Foundation

class SketchProcessor {
    enum SketchExportDeliverable: String {
        case pages = "pages",
        artboards = "artboards"
    }
    // TODO: Not die silently
    /// Creates a task to convert Sketch file
    /// - Parameter url: source file URL
    /// - Parameter destinationFolder: top folder where  converted artboards are stored in a sub-folder  as PNGs.
    func convertSketch(file url: URL, deliverables: SketchExportDeliverable = .artboards, destinationFolder: URL, completion: @escaping (Bool) -> ()) {
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
            deliverables.rawValue,
            url.path,
            "--output=\(subFolderURL.path)",
            "--formats=pdf",
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
    
    /// Converts Sketch files to PNGs.
    /// - Parameter urls: Array of Sketch file URLs
    /// - Parameter destinationPath: Output URL for converted files
    func convertSketch(urls: [URL], destinationPath: URL, group: DispatchGroup) throws {
        var isDir: ObjCBool = true
        if !FileManager.default
            .fileExists(atPath: destinationPath.path,
                                           isDirectory: &isDir) {
            do {
                try FileManager.default
                    .createDirectory(at: destinationPath,
                                        withIntermediateDirectories: true,
                                        attributes: [:])
            } catch {
                fatalError("Could not create directory at:\n\t\(destinationPath.path)")
            }
        }
        let queue = DispatchQueue.global(qos: .utility)
        for sketchFile in urls {
            group.enter()
            queue.async(group: group, qos: .background, flags: [], execute: {
                let filename = sketchFile.deletingLastPathComponent().lastPathComponent
                print("Converting: \(filename)")
                self.convertSketch(file: sketchFile,
                               destinationFolder: destinationPath,
                               completion: { isSuccess in
                                if isSuccess {
                                    print("Done converting \(filename)")
                                } else {
                                    print("\n×××\n\nConversion FAILED for \(filename)\n\n×××\n")
                                }
                                group.leave()
                })
            })
        }
    }
    
}
