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

func compile(filename: String) throws {
    let fileUrl = URL(fileURLWithPath: filename)
    let description = try loadDescription(from: fileUrl)
    let template = createTemplate(
        from: description, with: fileUrl.deletingLastPathComponent())
    let templateUrl = fileUrl.deletingPathExtension().appendingPathExtension("presentrt")

    try save(template, to: templateUrl)
}


func save(_ template: Template, to fileUrl: URL) throws {
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(template)
    let jsonString = String(data: jsonData, encoding: .utf8)

    try jsonString?.write(to: fileUrl, atomically: true, encoding: .utf8)
}


func createTemplate(from description: TemplateDescription, with baseUrl: URL) -> Template {
    let template =
        Template(
            template: TemplateAttribute(filename: "", contents: ""),
            stylesheet: TemplateAttribute(filename: "", contents: ""),
            fonts: [])

    return template
}


func loadDescription(from fileUrl: URL) throws -> TemplateDescription {
    let contents = try String(contentsOf: fileUrl, encoding: .utf8)
    let decoder = JSONDecoder()
    let description = try decoder.decode(TemplateDescription.self, from: Data(contents.utf8))

    return description
}
