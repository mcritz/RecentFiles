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
            SketchProcessor()
                .convertSketch(file: sketchFile,
                               destinationFolder: destinationPath,
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
}

command(
    Option<String>("path",
                   default: "Downloads",
                   description: "path to search, relative to user’s home folder. Default is `Downloads`"),
    Option<Double>("minutes",
                   default: 1_440,
                   description: "age of file in minutes. Default is 24 hours."),
    Option<String>("convert-sketch",
                    default: "",
                    description: "output directory for converted Sketch files. Not adding a valid path will skip conversion.")
) { path, minutes, destinationPathString in
    var searchURL = FileManager.default.homeDirectoryForCurrentUser
    let arguments = Array<String>(CommandLine.arguments.dropFirst())
    searchURL.appendPathComponent(path)
    var isValidSearchDirectory: ObjCBool = true
    guard FileManager.default.fileExists(atPath: searchURL.path, isDirectory: &isValidSearchDirectory),
        isValidSearchDirectory.boolValue else {
            fatalError("Not a something that can be searched:\n\t\(searchURL.path)")
    }
    print("Searching \(searchURL)\n for files modified in the last \(minutes) minutes")
    let fun = FileUpdateNotifier(searchURL: searchURL, within: minutes)
    let coder = JSONEncoder()
    let group = DispatchGroup()
    
    fun.recentFiles(at: fun.fileURLs, completion: { urls in
        let jsonEncodedPathStrings = try coder.encode(urls)
        do {
            let fileName = fileURL(pathComponents: arguments)
            print("\n\tWriting \(urls.count) files to:\n\t\(fileName.relativeString)")
            try jsonEncodedPathStrings.write(to: fileName)
        } catch {
            print("\tFAILED")
        }
        if destinationPathString.count > 0 {
            let conversionDestinationURL = FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent(destinationPathString)
            
            print("\n\nConverting Sketch Files\n\n")
            try convertSketch(urls: urls.filter {
                $0.pathExtension == "sketch"
            },
              destinationPath: conversionDestinationURL,
              group: group
            )
            
            let staticURLs = urls.filter {
                $0.pathExtension != "sketch"
            }
            
            handleStaticURLs: for staticURL in staticURLs {
                var isDirectory: ObjCBool = false
                guard FileManager.default
                    .fileExists(atPath: staticURL.path, isDirectory: &isDirectory),
                    !isDirectory.boolValue else {
                        print("Won’t copy directory or unreadable file\t\n\(staticURL.path)")
                        continue handleStaticURLs
                }
                let fileAttributes = try FileManager.default
                    .attributesOfItem(atPath: staticURL.path) as NSDictionary
                guard fileAttributes.fileSize() < 250_000_000 else {
                    print("Skipping: file is larger than 250MB\t\n\(staticURL.lastPathComponent)")
                    continue handleStaticURLs
                }
                
                let staticFileQueue = DispatchQueue.global(qos: .utility)
                group.enter()
                staticFileQueue.async {
                    do {
                        print("Copying \(staticURL.lastPathComponent)")
                        try FileManager.default
                        .copyItem(at: staticURL,
                                  to: conversionDestinationURL
                                    .appendingPathComponent(staticURL
                                        .lastPathComponent))
                    } catch {
                        print("Could not copy\n\t\(staticURL.path)")
                    }
                    group.leave()
                }
            }
            group.wait()
        } else {
            print("Not converting Sketch files.\n Conversion happens at by adding `--convert-sketch \"$HOME/some/directory/\"`")
        }
    })
    print("Completely Done")
}.run()
