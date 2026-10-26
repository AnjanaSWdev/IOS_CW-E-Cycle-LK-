//
//  Centrecsvparser.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation
 
/// Reads centres.csv. Columns are found by their header names, so column order does not matter.
enum CentreCSVParser {
 
    /// Splits CSV text into rows of fields. Handles quoted fields, commas and line breaks inside
    /// quotes, doubled quotes ("") and both \n and \r\n line endings.
    static func parseRows(_ text: String) -> [[String]] {
        var scalars = Array(text.unicodeScalars)
        if scalars.first == "\u{FEFF}" { scalars.removeFirst() }   // byte-order mark from Excel/Numbers
 
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
 
        func endRow() {
            row.append(field)
            field = ""
            if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }   // skip blank lines
            row = []
        }
 
        var i = 0
        while i < scalars.count {
            let c = scalars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < scalars.count, scalars[i + 1] == "\"" {
                        field.unicodeScalars.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.unicodeScalars.append(c)
                }
            } else if c == "\"" {
                inQuotes = true
            } else if c == "," {
                row.append(field)
                field = ""
            } else if c == "\n" {
                endRow()
            } else if c == "\r" {
                endRow()
                if i + 1 < scalars.count, scalars[i + 1] == "\n" { i += 1 }
            } else {
                field.unicodeScalars.append(c)
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty { endRow() }
        return rows
    }
 
    static func parseCentres(from text: String) -> [RecyclingCentre] {
        let rows = parseRows(text)
        guard let header = rows.first else { return [] }
 
        let index = Dictionary(
            header.enumerated().map { ($0.element.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )
 
        func value(_ row: [String], _ key: String) -> String {
            guard let position = index[key.lowercased()], position < row.count else { return "" }
            return row[position].trimmingCharacters(in: .whitespacesAndNewlines)
        }
 
        func number(_ row: [String], _ key: String) -> Double? {
            Double(value(row, key).replacingOccurrences(of: ",", with: "."))
        }
 
        return rows.dropFirst().compactMap { row in
            let id = value(row, "id")
            let name = value(row, "name")
            guard !id.isEmpty, !name.isEmpty else { return nil }
 
            let categories = value(row, "acceptedCategories")
                .split(separator: "|")
                .compactMap { ItemCategory(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
 
            return RecyclingCentre(
                id: id,
                name: name,
                kind: CentreKind(rawValue: value(row, "type")) ?? .other,
                address: value(row, "address"),
                district: value(row, "district"),
                latitude: number(row, "latitude"),
                longitude: number(row, "longitude"),
                phone: value(row, "phone"),
                openingHours: value(row, "openingHours"),
                acceptedCategories: Set(categories),
                needsConfirmation: value(row, "needsConfirmation").lowercased() == "yes",
                source: value(row, "source"),
                notes: value(row, "notes")
            )
        }
    }
}
 
