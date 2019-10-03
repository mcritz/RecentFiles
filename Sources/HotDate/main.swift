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
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

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
    Option<String>("path", default: "Downloads", description: "path to search, relative to user’s home folder")
) { path in
    var searchPath = FileManager.default.homeDirectoryForCurrentUser
    let arguments = Array<String>(CommandLine.arguments.dropFirst())
    searchPath.appendPathComponent(path)
    print("Searching \(searchPath)")
    let fun = FileUpdateNotifier(searchURL: searchPath)

    fun.recentFiles(at: fun.fileURLs, completion: { urls in
        let coder = JSONEncoder()
        let jsonEncodedPathStrings = try coder.encode(urls)
        do {
            let fileName = fileURL(pathComponents: arguments)
            print("\n\tWriting \(urls.count) files to:\n\t\(fileName.relativeString)")
            try jsonEncodedPathStrings.write(to: fileName)
        } catch {
            print("\tFAILED")
        }
    })
    print("Done")
}.run()
