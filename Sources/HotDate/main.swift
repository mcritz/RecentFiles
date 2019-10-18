//
//  main.swift
//  Updates
//
//  Created by Critz, Michael on 9/26/19.
//  Copyright © 2019 pixel.science. All rights reserved.
//
import Foundation
import Commander

func fileURL(pathComponents: [String], date: Date = Date()) -> URL {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"

    let formattedDateString = formatter.string(from: date)
    var filename = "Recent Files "
    for component in pathComponents {
        filename.append("\(component)-")
    }
    filename.append(formattedDateString)
    filename.append(".json")
    return FileManager
        .default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop", isDirectory: true)
        .appendingPathComponent("RecentFiles-\(formattedDateString).json")
}

command(
    Option<String>("path", default: "Downloads", description: "path to search, relative to user’s home folder. Default is `Downloads`"),
    Option<Double>("minutes", default: 1_440, description: "age of file in minutes. Default is 24 hours.")
) { path, minutes  in
    var searchPath = FileManager.default.homeDirectoryForCurrentUser
    let arguments = Array<String>(CommandLine.arguments.dropFirst())
    searchPath.appendPathComponent(path)
    print("Searching \(searchPath)\n for files modified in the last \(minutes) minutes")
    let fun = FileUpdateNotifier(searchURL: searchPath, within: minutes)
    let coder = JSONEncoder()
    
    fun.recentFiles(at: fun.fileURLs, completion: { urls in
        let jsonEncodedPathStrings = try coder.encode(urls)
        do {
            let fileName = fileURL(pathComponents: arguments)
            print("\n\tWriting \(urls.count) files to:\n\t\(fileName.relativeString)")
            try jsonEncodedPathStrings.write(to: fileName)
        } catch {
            print("\tFAILED")
        }
        let sketchURLs = urls.filter{ url -> Bool in
            return url.pathExtension == "sketch"
        }
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "science.pixel.sketchconversion")
        for sketchFile in sketchURLs {
            group.enter()
            queue.async(group: nil, qos: .background, flags: [], execute: {
                let filename = sketchFile.deletingLastPathComponent().lastPathComponent
                print("Converting: \(filename)")
                SketchProcessor()
                    .convertSketch(file: sketchFile,
                                   destinationFolder: FileManager
                                    .default
                                    .homeDirectoryForCurrentUser
                                    .appendingPathComponent("Desktop"),
                                   completion: { isSuccess in
                                    if isSuccess {
                                        print("Done converting \(filename)")
                                    } else {
                                        print("Conversion FAILED for \(filename)")
                                    }
                                    group.leave()
                })
            })
        }
        group.wait()
    })
    print("Done")
}.run()
