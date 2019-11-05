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

func compile(filename: String) throws {
    let fileUrl = URL(fileURLWithPath: filename)
    let description = try loadDescription(from: fileUrl)
    let baseUrl = fileUrl.deletingLastPathComponent()
    let template = try createTemplate(from: description, with: baseUrl)
    let templateUrl = fileUrl.deletingPathExtension().appendingPathExtension("presentrt")

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


func save(_ template: Template, to fileUrl: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let jsonData = try encoder.encode(template)
    let jsonString = String(data: jsonData, encoding: .utf8)

    try jsonString?.write(to: fileUrl, atomically: true, encoding: .utf8)
}


func createTemplate(from description: TemplateDescription, with baseUrl: URL) throws -> Template {
    let previewImage = try convertFile(description.previewImage, with: baseUrl)
    let template = try convertFile(description.template, with: baseUrl)
    let stylesheet = try convertFile(description.stylesheet, with: baseUrl)
    let remark = TemplateAttribute(
        filename: "remark.min.js", contents: getEncodedRemarkSource())
    let fonts = try description
                    .fonts
                    .map { filename in try convertFile(filename, with: baseUrl) }
    
    return Template(
                previewImage: previewImage,
                template: template,
                stylesheet: stylesheet,
                remark: remark,
                fonts: fonts)
}


func convertFile(_ filename: String, with baseUrl: URL) throws -> TemplateAttribute {
    let fileUrl = baseUrl.appendingPathComponent(filename)
    let data = try Data(contentsOf: fileUrl)
    
    return TemplateAttribute(filename: filename, contents: data.base64EncodedString())
}


func loadDescription(from fileUrl: URL) throws -> TemplateDescription {
    let contents = try String(contentsOf: fileUrl, encoding: .utf8)
    let decoder = JSONDecoder()
    let description = try decoder.decode(TemplateDescription.self, from: Data(contents.utf8))

    return description
}
