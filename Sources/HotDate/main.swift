//
//  main.swift
//  Updates
//
//  Created by Critz, Michael on 9/26/19.
//  Copyright © 2019 pixel.science. All rights reserved.
//
import Foundation

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

func main() {
    var searchPath = FileManager.default.homeDirectoryForCurrentUser
    let arguments = Array<String>(CommandLine.arguments.dropFirst())
    guard arguments.count > 0 else {
        fatalError("Please enter a search path like `Downloads` or `Documents/Projects/Apollo`")
    }
    for argument in arguments {
        searchPath.appendPathComponent(argument)
    }
    print("Searching \(searchPath)")
    let fun = FileUpdateNotifier(searchURL: searchPath)

    fun.recentFiles(at: fun.fileURLs, completion: { urls in
        let coder = JSONEncoder()
        let jsonEncodedPathStrings = try coder.encode(urls)
        do {
            let fileName = fileURL(pathComponents: arguments)
            print("\tWriting to:\n\t\(fileName.relativeString)")
            try jsonEncodedPathStrings.write(to: fileName)
        } catch {
            print("\tFAILED")
        }
    })
    print("Done")
}

main()
