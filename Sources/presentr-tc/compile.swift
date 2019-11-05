/*
    compile.swift
    presentr-tc

    Copyright 2019 Thomas Bonk
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
      http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
 */

import Foundation
import Cocoa

extension String {
    static let Extension = "presentrt"
    static let Contents = "Contents"
}

func compile(filename: String) throws {
    let fileUrl = URL(fileURLWithPath: filename)
    let templateUrl = fileUrl.deletingPathExtension().appendingPathExtension(.Extension)
    var description = try loadDescription(from: fileUrl)
    let baseUrl = fileUrl.deletingLastPathComponent()
    let template = try createTemplate(from: &description, to: templateUrl)

    try save(template, to: templateUrl)
    assignIcon(templateUrl, imageUrl: baseUrl.appendingPathComponent(description.previewImage))
}

func assignIcon(_ templateUrl: URL, imageUrl: URL) {
    NSWorkspace
        .shared
        .setIcon(
            NSImage(byReferencing: imageUrl),
            forFile: templateUrl.absoluteString,
            options: .excludeQuickDrawElementsIconCreationOption)
}


func save(_ template: FileWrapper, to fileUrl: URL) throws {
    try template.write(to: fileUrl, options: .atomic, originalContentsURL: nil)
}


func createTemplate(from description: inout TemplateDescription, to fileUrl: URL) throws -> FileWrapper {
    let baseUrl = fileUrl.deletingLastPathComponent()
    let previewImage = try convertFile(description.previewImage, with: baseUrl)
    let template = try convertFile(description.template, with: baseUrl)
    let stylesheet = try convertFile(description.stylesheet, with: baseUrl)
    let contents = FileWrapper(regularFileWithContents: try JSONEncoder().encode(description))
    let remark = try { () -> FileWrapper in
        if let remarkFile = description.remark {
            return try convertFile(remarkFile, with: baseUrl)
        } else {
            description.remark = "remark.min.js"
            return FileWrapper(regularFileWithContents: getRemarkSourceAsData())
        }
    }()
    let fileWrappers = [
        description.previewImage    : previewImage,
        description.template        : template,
        description.stylesheet      : stylesheet,
        description.remark!         : remark,
        .Contents                   : contents
    ]
    let fonts = try description
                    .fonts
                    .reduce([String : FileWrapper](), { (dictionary, filename) -> [String : FileWrapper] in
                        var dict = dictionary

                        dict[filename] = try convertFile(filename, with: baseUrl)
                        return dictionary

                    })
    let allFileWrappers =
        fileWrappers.merging(fonts, uniquingKeysWith: { (fw1, fw2) -> FileWrapper in fw1 })

    return FileWrapper(directoryWithFileWrappers: allFileWrappers)
}


func convertFile(_ filename: String, with baseUrl: URL) throws -> FileWrapper {
    let fileUrl = baseUrl.appendingPathComponent(filename)
    let data = try Data(contentsOf: fileUrl)

    return FileWrapper(regularFileWithContents: data)
}


func loadDescription(from fileUrl: URL) throws -> TemplateDescription {
    let contents = try String(contentsOf: fileUrl, encoding: .utf8)
    let decoder = JSONDecoder()
    let description = try decoder.decode(TemplateDescription.self, from: Data(contents.utf8))

    return description
}
