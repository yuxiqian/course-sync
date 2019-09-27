//
//  TextTable.swift
//  SwiftyTextTable
//
//  Created by Scott Hoyt on 2/3/16.
//  Copyright © 2016 Scott Hoyt. All rights reserved.
//

import Foundation

typealias Regex = NSRegularExpression

private let strippingPattern = "(?:\u{001B}\\[(?:[0-9]|;)+m)*(.*?)(?:\u{001B}\\[0m)+"

// We can safely force try this regex because the pattern has be tested to work.
// swiftlint:disable:next force_try
private let strippingRegex = try! Regex(pattern: strippingPattern, options: [])

private extension String {
    func stripped() -> String {
#if os(Linux)
        let length = NSString(string: self).length
#else
        let length = (self as NSString).length
#endif
        return strippingRegex.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: length),
            withTemplate: "$1"
        )
    }
}

// MARK: - TextTable structures

/// Used to create a tabular representation of data.
public struct TextTable {

    /// The columns within the table.
    private var columns: [TextTableColumn]

    /// The `String` used to separate columns in the table. Defaults to "|".
    public var columnFence = "|"

    /// The `String` used to separate rows in the table. Defaults to "-".
    public var rowFence = "-"

    /// The `String` used to mark the intersections of a `columnFence` and a `rowFence`. Defaults to "+".
    public var cornerFence = "+"

    /// The table's header text. If set to `nil`, no header will be rendered. Defaults to `nil`.
    public var header: String?

    /**
     Create a new `TextTable` from `TextTableColumn`s.

     - parameters:
     - columns: An `Array` of `TextTableColumn`s.
     - header: The table header. Defaults to `nil`.
     */
    public init(columns: [TextTableColumn], header: String? = nil) {
        self.columns = columns
        self.header = header
    }

    /**
     Create a new `TextTable` from an `TextTableRepresentable`s.

     - parameters:
     - objects: An `Array` of `TextTableRepresentable`s.
     - header: The table header. This will override the header specified by the `TextTableRepresentable`. Defaults to `nil`.
     */
    public init<T: TextTableRepresentable>(objects: [T], header: String? = nil) {
        self.header = header ?? T.tableHeader
        columns = T.columnHeaders.map { TextTableColumn(header: $0) }
        objects.forEach { addRow(values: $0.tableValues) }
    }

    /**
     Add a row to the table.

     - parameters:
     - values: The values contained in the new row.
     */
    public mutating func addRow(values: [CustomStringConvertible]) {
        let values = values.count >= columns.count ? values :
            values + [CustomStringConvertible](repeating: "", count: columns.count - values.count)
        columns = zip(columns, values).map {
            (column, value) in
            var column = column
            column.values.append(value.description)
            return column
        }
    }

    /**
     Render the table to a `String`.

     - returns: The `String` representation of the table.
     */
    public func render() -> String {
        let separator = fence(strings: columns.map({ column in
            return repeatElement(rowFence, count: column.width() + 2).joined()
        }), separator: cornerFence)

        let top = renderTableHeader() ?? separator

        let columnHeaders = fence(
            strings: columns.map({ " \($0.header.withPadding(count: $0.width())) " }),
            separator: columnFence
        )

        let values = columns.isEmpty ? "" : (0..<columns.first!.values.count).map({ rowIndex in
            fence(strings: columns.map({ " \($0.values[rowIndex].withPadding(count: $0.width())) " }), separator: columnFence)
        }).paragraph()

        return [top, columnHeaders, separator, values, separator].paragraph()
    }

    /**
     Render the table's header to a `String`.

     - returns: The `String` representation of the table header. `nil` if `header` is `nil`.
     */
    private func renderTableHeader() -> String? {
        guard let header = header else {
            return nil
        }

        let calculatewidth: (Int, TextTableColumn) -> Int = { $0 + $1.width() + 2 }
        let separator = cornerFence +
            repeatElement(rowFence, count: columns.reduce(0, calculatewidth) + columns.count - 1).joined() +
        cornerFence
#if swift(>=3.2)
        let separatorCount = separator.count
#else
        let separatorCount = separator.characters.count
#endif
        let title = fence(strings: [" \(header.withPadding(count: separatorCount - 4)) "], separator: columnFence)

        return [separator, title, separator].paragraph()
    }
}

/// Represents a column in a `TextTable`.
public struct TextTableColumn {

    /// The header for the column.
    public var header: String

    /// The values contained in this column. Each value represents another row.
    fileprivate var values: [String] = []

    /// Initialize a new column for inserting into a `TextTable`.
    public init(header: String) {
        self.header = header
    }

    /**
    The minimum width() of the column needed to accomodate all values in this column.
    - Complexity: O(n)
    */
    public func width() -> Int {
        return max(header.strippedLength(), values.reduce(0) { max($0, $1.strippedLength()) })
    }
}

// MARK: - TextTableRepresentable

/// A protocol used to create a `TextTable` from an object.
public protocol TextTableRepresentable {

    /// The text table header.
    static var tableHeader: String? { get }

    /// An array column headers to represent this object's data.
    static var columnHeaders: [String] { get }

    /// The values to render in the text table. Should have the same count as `columnHeaders`.
    var tableValues: [CustomStringConvertible] { get }
}

public extension TextTableRepresentable {
    /// Returns `nil`.
    static var tableHeader: String? {
        return nil
    }
}

private func fence(strings: [String], separator: String) -> String {
    return separator + strings.joined(separator: separator) + separator
}

public extension Array where Element: TextTableRepresentable {

    /**
     Returns a rendered text table containing the data in the array.
     - returns: A `String` containing the rendered text table.
    */
    func renderTextTable() -> String {
        let table = TextTable(objects: self)
        return table.render()
    }
}

// MARK: - Helper Extensions

private extension String {
    func withPadding(count: Int) -> String {
#if swift(>=3.2)
        let length = self.count
#else
        let length = self.characters.count
#endif
        if length < count {
            return self +
                repeatElement(" ", count: count - length).joined()
        }
        return self
    }

    func strippedLength() -> Int {
        var extraPaddingCount = 0
#if swift(>=3.2)
        for (_, value) in stripped().enumerated() {
            // check asia characters
            if ("\u{4E00}" <= value  && value <= "\u{9FA5}") {
                extraPaddingCount += 1
            }
        }
        return stripped().count + extraPaddingCount
#else
        for (_, value) in stripped().characters.enumerated() {
            if ("\u{4E00}" <= value  && value <= "\u{9FA5}") {
                extraPaddingCount += 1
            }
        }
        return stripped().characters.count + extraPaddingCount
#endif
    }
}

private extension Array where Element: CustomStringConvertible {
    func paragraph() -> String {
        return self.map({ $0.description }).joined(separator: "\n")
    }
}