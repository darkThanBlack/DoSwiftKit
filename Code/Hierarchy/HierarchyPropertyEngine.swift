//
//  HierarchyPropertyEngine.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit
import ObjectiveC.runtime

extension DO {

    struct HierarchyPropertyOverride: Decodable {
        let enumType: String?
        let desc: String?
        let userEditable: Bool?
    }

    struct HierarchyClassEntry: Decodable {
        let properties: [String]
        let overrides: [String: DO.HierarchyPropertyOverride]?
    }

    struct HierarchyEnumValue {
        let value: Int
        let name: String
    }

    enum ValueKind {
        case bool(Bool)
        case int(Int)
        case double(Double)
        case text(String)
        case color(UIColor)
        case font(UIFont)
        case image(UIImage)
        case date(Date)
        case attributedText(NSAttributedString)
        case frame(CGRect)
        case point(CGPoint)
        case size(CGSize)
        case insets(UIEdgeInsets)
        case enumValue(raw: Int, table: String, name: String)
        case unknown(Any)

        /// Classifies a KVC result by runtime type. Order matters: `UIColor` / `UIFont` /
        /// `UIImage` are objects and must precede `NSNumber`, and `NSValue` needs its encoding
        /// inspected because `CGRect` and `CGSize` share a class.
        static func probe(_ value: Any) -> DO.ValueKind {
            switch value {
            case let color as UIColor: return .color(color)
            // CF types bridge to each other without a runtime check, so `as? CGColor`
            // would also "succeed" for unrelated objects; compare the type ID instead.
            case let object as AnyObject where isCGColorValue(object):
                return .color(UIColor(cgColor: object as! CGColor))

            case let number as NSNumber:
                switch String(cString: number.objCType) {
                case "c", "C", "B": return .bool(number.boolValue)
                case "d", "f":      return .double(number.doubleValue)
                default:            return .int(number.intValue)
                }

            case let box as NSValue:
                let encoding = String(cString: box.objCType)
                if encoding.contains("CGRect")       { return .frame(box.cgRectValue) }
                if encoding.contains("CGPoint")      { return .point(box.cgPointValue) }
                if encoding.contains("CGSize")       { return .size(box.cgSizeValue) }
                if encoding.contains("UIEdgeInsets") { return .insets(box.uiEdgeInsetsValue) }
                return .unknown(value)

            case let font as UIFont:                   return .font(font)
            case let image as UIImage:                 return .image(image)
            case let date as Date:                     return .date(date)
            case let attributed as NSAttributedString: return .attributedText(attributed)
            case let text as String:                   return .text(text)
            case let cls as AnyClass:                  return .unknown(String(describing: cls))

            default:
                return .unknown(value)
            }
        }

        var boxed: Any {
            switch self {
            case .bool(let v):   return NSNumber(value: v)
            case .int(let v):    return NSNumber(value: v)
            case .double(let v): return NSNumber(value: v)
            case .text(let v):   return v
            case .color(let v):  return v
            case .font(let v):   return v
            case .image(let v):  return v
            case .date(let v):   return v
            case .attributedText(let v): return v
            case .frame(let v):  return NSValue(cgRect: v)
            case .point(let v):  return NSValue(cgPoint: v)
            case .size(let v):   return NSValue(cgSize: v)
            case .insets(let v): return NSValue(uiEdgeInsets: v)
            case .enumValue(let raw, _, _): return NSNumber(value: raw)
            case .unknown(let v): return v
            }
        }
    }

    struct DoSwiftHierarchyDefineRoot: Decodable {
        /// One tree per inspected subject kind; both share the same entry schema.
        let views: [String: DO.HierarchyClassEntry]
        let layers: [String: DO.HierarchyClassEntry]
        let enums: [String: [String: String]]
    }

    struct HierarchyEditDescriptor {
        let key: String
        let kind: DO.ValueKind
        let writeKey: String
    }

    /// Property panel driven by `DoSwiftHierarchyDefine.json`.
    ///
    /// The JSON has one entry tree per subject kind: `views` for `UIView` subclasses and
    /// `layers` for `CALayer` subclasses. Whichever tree applies says which class exposes which
    /// keys; this class reads them with KVC and renders one row each. Lookup walks the class
    /// chain from `NSObject` down, so a subclass entry wins and the nearest declaring class
    /// supplies the overrides. A key only shows when the object
    /// answers its getter. Writing needs `userEditable`, a parseable `ValueKind` and a real
    /// setter — miss one and the row stays read-only.
    class HierarchyPropertyEngine {

        static let shared = DO.HierarchyPropertyEngine()

        private var views: [String: DO.HierarchyClassEntry] = [:]
        private var layers: [String: DO.HierarchyClassEntry] = [:]
        private var enumTables: [String: [DO.HierarchyEnumValue]] = [:]

        private init() {
            loadJSON()
        }

        private func loadJSON() {
            guard let url = resolveURL() else {
                print("[Hierarchy] DoSwiftHierarchyDefine.json not found. Check Bundle resource.")
                return
            }
            do {
                let data = try Data(contentsOf: url)
                let root = try JSONDecoder().decode(DO.DoSwiftHierarchyDefineRoot.self, from: data)
                views = root.views
                layers = root.layers
                enumTables = root.enums.mapValues { table -> [DO.HierarchyEnumValue] in
                    table.compactMap { key, name in
                        Int(key).map { DO.HierarchyEnumValue(value: $0, name: name) }
                    }
                    .sorted { $0.value < $1.value }
                }
            } catch {
                print("[Hierarchy] Failed to load DoSwiftHierarchyDefine.json: \(error)")
            }
        }

        /// Resolves the JSON resource: a host that drops the file into the main bundle wins,
        /// otherwise it comes from `DO.resourceBundle` (SPM → `Bundle.module`,
        /// CocoaPods → `DoSwiftKitResources.bundle`).
        private func resolveURL() -> URL? {
            if let url = Bundle.main.url(forResource: "DoSwiftHierarchyDefine", withExtension: "json") {
                return url
            }
            return DO.resourceBundle.url(forResource: "DoSwiftHierarchyDefine", withExtension: "json")
        }

        /// `layers` for CALayer subclasses, `views` for everything else.
        private func tree(for object: NSObject) -> [String: DO.HierarchyClassEntry] {
            return object is CALayer ? layers : views
        }

        /// Subclass entries only: the class chain from NSObject down, one section per entry.
        func categoryModels(for object: NSObject) -> [DO.HierarchyCategoryModel] {
            let chain = classChain(object)
            let entries = tree(for: object)
            return chain.compactMap { className in
                guard let entry = entries[className] else { return nil }
                let rows = entry.properties.compactMap {
                    cellModel(for: object, key: $0, chain: chain, requiresDeclaration: true)
                }
                return rows.isEmpty ? nil : DO.HierarchyCategoryModel(title: className, items: rows)
            }
        }

        func cellModel(for object: NSObject, key: String) -> DO.HierarchyCellModel? {
            return cellModel(for: object, key: key, chain: classChain(object),
                             requiresDeclaration: false)
        }

        private struct ResolvedProperty {
            let key: String
            let kind: DO.ValueKind?
            let desc: String?
            let isUserEditable: Bool
        }

        private func cellModel(
            for object: NSObject,
            key: String,
            chain: [String],
            requiresDeclaration: Bool
        ) -> DO.HierarchyCellModel? {
            guard let resolved = resolve(key: key, object: object, chain: chain,
                                         requiresDeclaration: requiresDeclaration),
                  let model = makeCellModel(for: object, resolved: resolved)
            else { return nil }

            if resolved.isUserEditable, let kind = resolved.kind, canEdit(kind),
               !key.contains("."), let writeKey = kvcWriteKey(for: key, on: object) {
                model.edit = DO.HierarchyEditDescriptor(key: key, kind: kind, writeKey: writeKey)
            }
            return model
        }

        private func resolve(
            key: String,
            object: NSObject,
            chain: [String],
            requiresDeclaration: Bool
        ) -> ResolvedProperty? {
            let entries = tree(for: object)
            // The nearest declaring class supplies the overrides.
            let declaring = chain.first { entries[$0]?.properties.contains(key) == true }
            if requiresDeclaration, declaring == nil { return nil }

            let override = declaring.flatMap { entries[$0]?.overrides?[key] }
            let isUserEditable = override?.userEditable ?? true

            guard let value = safeValue(forKeyPath: key, on: object) else { return nil }

            let kind: DO.ValueKind
            if let table = override?.enumType {
                let raw = (value as? Int) ?? (value as? NSNumber)?.intValue ?? 0
                kind = .enumValue(raw: raw, table: table, name: enumName(table, raw))
            } else {
                kind = DO.ValueKind.probe(value)
            }

            return ResolvedProperty(key: key, kind: kind,
                                    desc: override?.desc, isUserEditable: isUserEditable)
        }

        private func makeCellModel(for object: NSObject, resolved: ResolvedProperty) -> DO.HierarchyCellModel? {
            guard let kind = resolved.kind else { return nil }

            let model = DO.HierarchyCellModel(title: resolved.desc ?? resolved.key,
                                              detailTitle: displayText(of: kind))
            model.noneInsets()
            return model
        }

        func displayText(of kind: DO.ValueKind) -> String {
            switch kind {
            case .bool(let v):          return v ? "true" : "false"
            case .int(let v):           return "\(v)"
            case .double(let v):        return DO.HierarchyFormatterTool.format(NSNumber(value: v))
            case .text(let v):          return formatText(v)
            case .color(let v):         return DO.HierarchyFormatterTool.description(of: v)
            case .font(let v):          return fontDescription(v)
            case .image(let v):         return formatImage(v)
            case .date(let v):          return DO.HierarchyFormatterTool.string(from: v) ?? "<null>"
            case .attributedText:       return "Attributed Text"
            case .frame(let v):         return DO.HierarchyFormatterTool.string(from: v)
            case .point(let v):         return pointDescription(v)
            case .size(let v):          return sizeDescription(v)
            case .insets(let v):        return insetsDescription(v)
            case .enumValue(_, _, let name): return name
            case .unknown(let v):       return formatObject(v)
            }
        }

        func parsed(_ string: String, into kind: DO.ValueKind) -> DO.ValueKind? {
            switch kind {
            case .bool:
                switch string.lowercased() {
                case "true", "1", "yes", "on":  return .bool(true)
                case "false", "0", "no", "off": return .bool(false)
                default:                        return nil
                }

            case .text:
                return .text(string)                        // nothing to parse

            case .enumValue(_, let table, _):
                if let raw = Int(string) { return .enumValue(raw: raw, table: table, name: enumName(table, raw)) }
                guard let hit = enumTables[table]?.first(where: { $0.name.caseInsensitiveCompare(string) == .orderedSame })
                else { return nil }
                return .enumValue(raw: hit.value, table: table, name: hit.name)

            case .int:
                return Int(string).map(DO.ValueKind.int)

            case .double:
                return Double(string).map(DO.ValueKind.double)

            case .color:
                return DO.HierarchyFormatterTool.color(from: string).map(DO.ValueKind.color)

            case .font(let current):
                return Double(string).map { DO.ValueKind.font(current.withSize(CGFloat($0))) }

            case .date:
                return DO.HierarchyFormatterTool.date(from: string).map(DO.ValueKind.date)

            case .size, .insets:
                return nil

            case .frame, .point:
                return nil

            case .image, .attributedText:
                return nil

            case .unknown:
                return nil                                  // unknown probe -> no editor
            }
        }

        private func canEdit(_ kind: DO.ValueKind) -> Bool {
            switch kind {
            case .bool, .text, .int, .double, .enumValue,
                 .color, .font, .date, .size, .insets,
                 .frame, .point:                            return true
            case .image, .attributedText:
                return false
            case .unknown:
                return false                                // unknown probe
            }
        }

        private func enumName(_ table: String, _ rawValue: Int) -> String {
            enumTables[table]?.first { $0.value == rawValue }?.name ?? "\(rawValue)"
        }

        func enumOptions(for enumType: String, currentRawValue: Int)
            -> (names: [String], rawValues: [Int], currentIndex: Int?) {
            guard let table = enumTables[enumType] else { return ([], [], nil) }
            return (table.map(\.name), table.map(\.value), table.firstIndex { $0.value == currentRawValue })
        }

        func enumValue(for enumType: String, at index: Int) -> Int? {
            guard let table = enumTables[enumType], table.indices.contains(index) else { return nil }
            return table[index].value
        }

        /// Applies an edit. Each guard mirrors one in the UI, so a rejection means the JSON and
        /// the live value disagree — log it, never crash the host app over a debug panel.
        func write(_ newValue: DO.ValueKind, forKey key: String, to object: NSObject) {
            guard let resolved = resolve(key: key, object: object, chain: classChain(object),
                                        requiresDeclaration: false),
                  resolved.isUserEditable, let oldKind = resolved.kind else {
                print("[Hierarchy] \(key): this row is read-only")
                return
            }
            guard canEdit(oldKind) else {
                print("[Hierarchy] \(key): no editor for this kind yet")
                return
            }
            guard !key.contains(".") else {
                print("[Hierarchy] \(key): key paths are not written from this panel")
                return
            }
            guard let writeKey = kvcWriteKey(for: key, on: object) else { return }

            object.setValue(boxedForWrite(newValue, key: key, on: object), forKey: writeKey)

            if let view = object as? UIView {
                DO.HierarchyLayoutRefresh.refresh(view)
            } else if let layer = object as? CALayer {
                layer.setNeedsDisplay()
            }
        }

        /// `CGColor` properties (borderColor, fillColor, …) reject a `UIColor` from KVC.
        private func boxedForWrite(_ value: DO.ValueKind, key: String, on object: NSObject) -> Any {
            if case let .color(color) = value, isCGColorValue(safeValue(forKeyPath: key, on: object)) {
                return color.cgColor
            }
            return value.boxed
        }


        private static func writeKeyCandidates(for propertyName: String) -> [String] {
            var candidates = [propertyName]
            if propertyName.hasPrefix("is"), propertyName.count > 2 {
                let stripped = propertyName.dropFirst(2)
                candidates.append(stripped.prefix(1).lowercased() + stripped.dropFirst())
            }
            return candidates
        }

        /// Finds the setter KVC can actually call. `isHidden` is written through `setHidden:`,
        /// not `setIsHidden:`, which is why there is a second candidate.
        private func kvcWriteKey(for propertyName: String, on object: NSObject) -> String? {
            let candidates = Self.writeKeyCandidates(for: propertyName)
            let setterName = { (name: String) in "set" + name.prefix(1).uppercased() + name.dropFirst() + ":" }

            if let hit = candidates.first(where: { object.responds(to: NSSelectorFromString(setterName($0))) }) {
                return hit
            }
            print("[Hierarchy] \(propertyName): \(type(of: object)) has no setter, "
                + "tried \(candidates.map(setterName))")
            return nil
        }

        /// Superclass chain with `NSObject` first, so sections read base class -> subclass.
        private func classChain(_ object: NSObject) -> [String] {
            var chain: [String] = []
            var cls: AnyClass? = type(of: object)
            while let c = cls {
                let name = String(describing: c)
                chain.append(name)
                if name == "NSObject" { break }
                cls = class_getSuperclass(c)
            }
            return chain.reversed()
        }

        /// KVC read that returns nil when the key path does not resolve instead of crashing.
        private func safeValue(forKeyPath keyPath: String, on object: NSObject) -> Any? {
            let components = keyPath.split(separator: ".").map(String.init)
            var current: NSObject = object
            for (i, key) in components.enumerated() {
                guard respondsToGetter(current, key) else { return nil }
                let value = current.value(forKey: key)
                if i == components.count - 1 {
                    return value
                }
                guard let next = value as? NSObject else { return nil }
                current = next
            }
            return nil
        }

        /// KVC getter lookup: get<Key>, <key>, is<Key> (also covers getter=is<X> renames).
        private func respondsToGetter(_ object: NSObject, _ key: String) -> Bool {
            let capitalized = key.prefix(1).uppercased() + key.dropFirst()
            for selector in ["get\(capitalized)", key, "is\(capitalized)"] {
                if object.responds(to: NSSelectorFromString(selector)) {
                    return true
                }
            }
            return false
        }

        private func fontDescription(_ font: UIFont) -> String {
            let isSystem = font.familyName == UIFont.systemFont(ofSize: font.pointSize).familyName
            return String(format: "%@ %0.2f", isSystem ? "System" : font.familyName, font.pointSize)
        }

        private func formatText(_ value: Any?) -> String {
            guard let value = value else { return "<nil>" }
            if let s = value as? String {
                return s.isEmpty ? "<empty string>" : s
            }
            return "\(value)"
        }

        func formatObject(_ value: Any?) -> String {
            guard let value = value else { return "<nil>" }
            if let s = value as? String {
                return s.isEmpty ? "<empty string>" : s
            }
            return "\(value)"
        }

        func formatImage(_ image: UIImage?) -> String {
            return image?.description ?? "No image"
        }

        func pointDescription(_ point: CGPoint) -> String {
            return "X: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(point.x))))   Y: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(point.y))))"
        }

        func sizeDescription(_ size: CGSize) -> String {
            return "W: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(size.width))))   H: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(size.height))))"
        }

        func insetsDescription(_ insets: UIEdgeInsets) -> String {
            let f = { (v: CGFloat) in DO.HierarchyFormatterTool.format(NSNumber(value: Double(v))) }
            return "T: \(f(insets.top))   L: \(f(insets.left))   B: \(f(insets.bottom))   R: \(f(insets.right))"
        }
    }
}

/// CF types bridge to each other without a runtime check, so `as? CGColor` also "succeeds"
/// for unrelated objects; the type ID is the only reliable test.
private func isCGColorValue(_ value: Any?) -> Bool {
    guard let value = value else { return false }
    return CFGetTypeID(value as CFTypeRef) == CGColor.typeID
}
