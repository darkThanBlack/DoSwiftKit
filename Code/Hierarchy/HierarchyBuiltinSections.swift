//
//  HierarchyBuiltinSections.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/09
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// One row of a code-backed section. There is no key or writeKey: read and write are
    /// closures over the view itself, so non-property APIs (priority setters) fit as well.
    struct HierarchyBuiltinRow {
        let title: String
        let detail: String
        let kind: DO.ValueKind
        let write: ((DO.ValueKind) -> Void)?
        let badge: UIImage?
        let input: (() -> DO.HierarchyValueInput?)?

        init(
            title: String,
            detail: String,
            kind: DO.ValueKind,
            write: ((DO.ValueKind) -> Void)? = nil,
            badge: UIImage? = nil,
            input: (() -> DO.HierarchyValueInput?)? = nil
        ) {
            self.title = title
            self.detail = detail
            self.kind = kind
            self.write = write
            self.badge = badge
            self.input = input
        }
    }

    struct HierarchyBuiltinSection {
        let title: String
        let rows: [DO.HierarchyBuiltinRow]
    }

    /// Fixed parts of the object model, split by the detail page's segments.
    enum HierarchyBuiltinSections {

        static let enumTables: [String: [DO.HierarchyEnumValue]] = [
            "UIViewContentMode": [
                .init(value: 0, name: "scaleToFill"),
                .init(value: 1, name: "scaleAspectFit"),
                .init(value: 2, name: "scaleAspectFill"),
                .init(value: 3, name: "redraw"),
                .init(value: 4, name: "center"),
                .init(value: 5, name: "top"),
                .init(value: 6, name: "bottom"),
                .init(value: 7, name: "left"),
                .init(value: 8, name: "right"),
                .init(value: 9, name: "topLeft"),
                .init(value: 10, name: "topRight"),
                .init(value: 11, name: "bottomLeft"),
                .init(value: 12, name: "bottomRight"),
            ],
            "UIUserInterfaceStyle": [
                .init(value: 0, name: "unspecified"),
                .init(value: 1, name: "light"),
                .init(value: 2, name: "dark"),
            ],
            "UIUserInterfaceSizeClass": [
                .init(value: 0, name: "unspecified"),
                .init(value: 1, name: "compact"),
                .init(value: 2, name: "regular"),
            ],
            "UITraitEnvironmentLayoutDirection": [
                .init(value: -1, name: "unspecified"),
                .init(value: 0, name: "leftToRight"),
                .init(value: 1, name: "rightToLeft"),
            ],
            "UIUserInterfaceLayoutDirection": [
                .init(value: 0, name: "leftToRight"),
                .init(value: 1, name: "rightToLeft"),
            ],
            "CALayerCornerCurve": [
                .init(value: 0, name: "circular"),
                .init(value: 1, name: "continuous"),
            ],
            "UISemanticContentAttribute": [
                .init(value: 0, name: "unspecified"),
                .init(value: 1, name: "playback"),
                .init(value: 2, name: "spatial"),
                .init(value: 3, name: "forceLeftToRight"),
                .init(value: 4, name: "forceRightToLeft"),
            ],
        ]

        private static let badgeImage: UIImage? = {
            let config = UIImage.SymbolConfiguration(pointSize: 8, weight: .regular)
            return UIImage(systemName: "circle.fill", withConfiguration: config)?
                .withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
        }()

        // MARK: - Segments

        /// Merged "properties" segment: fixed identity / appearance rows.
        static func propertySections(for view: UIView) -> [DO.HierarchyBuiltinSection] {
            return [identity(view), appearance(view)]
        }

        /// "layer" segment: drawing, transform, animations, then the low-value rendering knobs.
        static func layerSections(for view: UIView) -> [DO.HierarchyBuiltinSection] {
            return [drawing(view), transform(view), animations(view), layerDiagnostics(view)]
        }

        /// "Auto Layout" segment without the runtime constraints, which the page inserts.
        static func autoLayoutSections(for view: UIView) -> [DO.HierarchyBuiltinSection] {
            return [common(view), diagnostics(view), effect(view), traits(view)]
        }

        // MARK: - Properties

        private static func identity(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let owner = ownerViewController(of: view).map { String(describing: type(of: $0)) } ?? "nil"

            return DO.HierarchyBuiltinSection(title: "Object", rows: [
                row("class", .text(String(describing: type(of: view)))),
                row("description", .text(view.description)),
                row("viewController.class", .text(owner)),
            ])
        }

        /// The nearest controller in the responder chain: a view's `nextResponder` is its
        /// superview, and the controller is the `nextResponder` of its own root view.
        private static func ownerViewController(of view: UIView) -> UIViewController? {
            var responder: UIResponder? = view
            while let current = responder {
                if let controller = current as? UIViewController { return controller }
                responder = current.next
            }
            return nil
        }

        private static func appearance(_ view: UIView) -> DO.HierarchyBuiltinSection {
            var rows: [DO.HierarchyBuiltinRow] = [
                row("contentMode", enumKind("UIViewContentMode", raw: Int(view.contentMode.rawValue))) { [weak view] value in
                    guard let view = view, case let .enumValue(raw, _, _) = value,
                          let mode = UIView.ContentMode(rawValue: raw) else { return }
                    view.contentMode = mode
                    refresh(view)
                },
                row("tag", .int(view.tag)) { [weak view] value in
                    guard let view = view, case let .int(number) = value else { return }
                    view.tag = number
                    refresh(view)
                },
                bool("isUserInteractionEnabled", view, \.isUserInteractionEnabled),
                bool("isMultipleTouchEnabled", view, \.isMultipleTouchEnabled),
                row("alpha", .double(Double(view.alpha))) { [weak view] value in
                    guard let view = view, case let .double(number) = value else { return }
                    view.alpha = CGFloat(number)
                    refresh(view)
                },
            ]

            if let color = view.backgroundColor {
                rows.append(row("backgroundColor", .color(color)) { [weak view] value in
                    guard let view = view, case let .color(color) = value else { return }
                    view.backgroundColor = color
                    refresh(view)
                })
            }

            if let color = view.tintColor {
                rows.append(row("tintColor", .color(color)) { [weak view] value in
                    guard let view = view, case let .color(color) = value else { return }
                    view.tintColor = color
                    refresh(view)
                })
            }

            rows += [
                bool("isOpaque", view, \.isOpaque),
                bool("isHidden", view, \.isHidden),
                bool("clipsToBounds", view, \.clipsToBounds),
                row("isFirstResponder", .bool(view.isFirstResponder)),
                row("mask", .text(view.mask.map { String(describing: type(of: $0)) } ?? "nil")),
            ]

            return DO.HierarchyBuiltinSection(title: "UIView", rows: rows)
        }

        // MARK: - Layer

        /// The fixed CALayer surface: borders, corners and shadow. Anything shared with the
        /// view (alpha, backgroundColor, clipsToBounds) stays in the properties segment.
        private static func drawing(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let layer = view.layer

            var rows: [DO.HierarchyBuiltinRow] = [
                row("layer.class", .text(String(describing: type(of: layer)))),
                row("cornerRadius", .double(Double(layer.cornerRadius))) { [weak view] value in
                    guard let view = view, case let .double(number) = value else { return }
                    view.layer.cornerRadius = CGFloat(number)
                    view.layer.setNeedsDisplay()
                },
                row("cornerCurve",
                    enumKind("CALayerCornerCurve", raw: layer.cornerCurve == .continuous ? 1 : 0)) { [weak view] value in
                    guard let view = view, case let .enumValue(raw, _, _) = value else { return }
                    view.layer.cornerCurve = raw == 1 ? .continuous : .circular
                    view.layer.setNeedsDisplay()
                },
                row("borderWidth", .double(Double(layer.borderWidth))) { [weak view] value in
                    guard let view = view, case let .double(number) = value else { return }
                    view.layer.borderWidth = CGFloat(number)
                    view.layer.setNeedsDisplay()
                },
            ]

            if let borderColor = layer.borderColor.map({ UIColor(cgColor: $0) }) {
                rows.append(row("borderColor", .color(borderColor)) { [weak view] value in
                    guard let view = view, case let .color(color) = value else { return }
                    view.layer.borderColor = color.cgColor
                    view.layer.setNeedsDisplay()
                })
            }

            if let shadowColor = layer.shadowColor.map({ UIColor(cgColor: $0) }) {
                rows.append(row("shadowColor", .color(shadowColor)) { [weak view] value in
                    guard let view = view, case let .color(color) = value else { return }
                    view.layer.shadowColor = color.cgColor
                    view.layer.setNeedsDisplay()
                })
            }

            rows += [
                row("shadowOpacity", .double(Double(layer.shadowOpacity))) { [weak view] value in
                    guard let view = view, case let .double(number) = value else { return }
                    view.layer.shadowOpacity = Float(number)
                    view.layer.setNeedsDisplay()
                },
                row("shadowOffset", .size(layer.shadowOffset)) { [weak view] value in
                    guard let view = view, case let .size(size) = value else { return }
                    view.layer.shadowOffset = size
                    view.layer.setNeedsDisplay()
                },
                row("shadowRadius", .double(Double(layer.shadowRadius))) { [weak view] value in
                    guard let view = view, case let .double(number) = value else { return }
                    view.layer.shadowRadius = CGFloat(number)
                    view.layer.setNeedsDisplay()
                },
                row("shadowPath", .text(shadowPathText(layer.shadowPath))),
            ]

            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionDrawing, rows: rows)
        }

        /// Layer position / anchor / z and both transforms. The 2D matrix is the editable side;
        /// the 4x4 is read-only because 16 editable fields are a footgun.
        private static func transform(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let layer = view.layer
            let current = view.transform
            let values = [Double(current.a), Double(current.b), Double(current.c),
                          Double(current.d), Double(current.tx), Double(current.ty)]

            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionTransform, rows: [
                row("position", .point(layer.position)) { [weak view] value in
                    guard let view = view, case let .point(point) = value else { return }
                    view.layer.position = point
                    refresh(view)
                },
                row("anchorPoint", .point(layer.anchorPoint)) { [weak view] value in
                    guard let view = view, case let .point(point) = value else { return }
                    view.layer.anchorPoint = point
                    refresh(view)
                },
                row("zPosition", .double(Double(layer.zPosition))) { [weak view] value in
                    guard let view = view, case let .double(number) = value else { return }
                    view.layer.zPosition = CGFloat(number)
                    refresh(view)
                },
                row("transform",
                    .text(affineCSV(values)),
                    detail: transformText(current),
                    write: { [weak view] value in
                        guard let view = view, let transform = affineTransform(from: value) else { return }
                        view.transform = transform
                        refresh(view)
                    },
                    input: { [weak view] in
                        guard let view = view else { return nil }
                        let transform = view.transform
                        return DO.HierarchyNumberGridView(
                            labels: ["a", "b", "c", "d", "tx", "ty"],
                            values: [Double(transform.a), Double(transform.b), Double(transform.c),
                                     Double(transform.d), Double(transform.tx), Double(transform.ty)]
                        ) { .text(affineCSV($0)) }
                    }),
                row("transform3D", .text(matrixText(layer.transform))),
            ])
        }

        /// One read-only row: the keys Core Animation currently has attached to this layer.
        private static func animations(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let keys = view.layer.animationKeys() ?? []
            let text = keys.isEmpty ? "none" : keys.joined(separator: ", ")

            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionAnimations, rows: [
                row("animationKeys", .text(text)),
            ])
        }

        /// Rarely touched rendering knobs, values only. A scale that differs from the screen is
        /// not proof of a bug (custom contents, multi-scene, intentional rasterization), so these
        /// rows carry no badge.
        private static func layerDiagnostics(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let layer = view.layer

            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionDiagnostics, rows: [
                row("contentsScale", .double(Double(layer.contentsScale))),
                row("contentsGravity", .text(layer.contentsGravity.rawValue)),
                row("shouldRasterize", .bool(layer.shouldRasterize)),
                row("rasterizationScale", .double(Double(layer.rasterizationScale))),
            ])
        }

        // MARK: - Auto Layout

        private static func common(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let huggingH = view.contentHuggingPriority(for: .horizontal)
            let huggingV = view.contentHuggingPriority(for: .vertical)
            let compressionH = view.contentCompressionResistancePriority(for: .horizontal)
            let compressionV = view.contentCompressionResistancePriority(for: .vertical)

            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionCommon, rows: [
                row("frame", .frame(view.frame)) { [weak view] value in
                    guard let view = view, case let .frame(rect) = value else { return }
                    view.frame = rect
                    refresh(view)
                },
                row("bounds", .frame(view.bounds)) { [weak view] value in
                    guard let view = view, case let .frame(rect) = value else { return }
                    view.bounds = rect
                    refresh(view)
                },
                row("center", .point(view.center)) { [weak view] value in
                    guard let view = view, case let .point(point) = value else { return }
                    view.center = point
                    refresh(view)
                },
                bool("translatesAutoresizingMaskIntoConstraints", view, \.translatesAutoresizingMaskIntoConstraints),

                row("contentHuggingPriority",
                    .point(CGPoint(x: Double(huggingH.rawValue), y: Double(huggingV.rawValue))),
                    write: { [weak view] value in
                        guard let view = view, case let .point(point) = value else { return }
                        view.setContentHuggingPriority(UILayoutPriority(Float(point.x)), for: .horizontal)
                        view.setContentHuggingPriority(UILayoutPriority(Float(point.y)), for: .vertical)
                        refresh(view)
                    },
                    input: priorityInput(for: view, hugging: true)),

                row("contentCompressionResistancePriority",
                    .point(CGPoint(x: Double(compressionH.rawValue), y: Double(compressionV.rawValue))),
                    write: { [weak view] value in
                        guard let view = view, case let .point(point) = value else { return }
                        view.setContentCompressionResistancePriority(UILayoutPriority(Float(point.x)), for: .horizontal)
                        view.setContentCompressionResistancePriority(UILayoutPriority(Float(point.y)), for: .vertical)
                        refresh(view)
                    },
                    input: priorityInput(for: view, hugging: false)),
            ])
        }

        private static func priorityInput(for view: UIView, hugging: Bool) -> () -> DO.HierarchyValueInput? {
            return { [weak view] in
                guard let view = view else { return nil }
                let horizontal = hugging
                    ? view.contentHuggingPriority(for: .horizontal)
                    : view.contentCompressionResistancePriority(for: .horizontal)
                let vertical = hugging
                    ? view.contentHuggingPriority(for: .vertical)
                    : view.contentCompressionResistancePriority(for: .vertical)
                return DO.HierarchyNumberGridView(
                    labels: ["horizontal", "vertical"],
                    values: [Double(horizontal.rawValue), Double(vertical.rawValue)],
                    presets: DO.HierarchyEditorStyle.layoutPriorityPresets
                ) {
                    .point(CGPoint(x: $0[0], y: $0[1]))
                }
            }
        }

        private static func diagnostics(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let horizontal = view.constraintsAffectingLayout(for: .horizontal).count
            let vertical = view.constraintsAffectingLayout(for: .vertical).count

            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionDiagnostics, rows: [
                row("intrinsicContentSize", .size(view.intrinsicContentSize)),
                row("hasAmbiguousLayout", .bool(view.hasAmbiguousLayout)),
                row("constraintsAffectingLayout", .text("H \(horizontal) · V \(vertical)")),
            ])
        }

        private static func effect(_ view: UIView) -> DO.HierarchyBuiltinSection {
            let marginsFrame = view.layoutMarginsGuide.layoutFrame
            let safeFrame = view.safeAreaLayoutGuide.layoutFrame

            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionEffective, rows: [
                row("layoutMargins", .insets(view.layoutMargins)) { [weak view] value in
                    guard let view = view, case let .insets(insets) = value else { return }
                    view.layoutMargins = insets
                    refresh(view)
                },
                row("layoutMarginsGuide", .frame(marginsFrame)),
                row("safeAreaInsets", .insets(view.safeAreaInsets)),
                row("safeAreaLayoutGuide", .frame(safeFrame)),
                row("requiresConstraintBasedLayout", .bool(type(of: view).requiresConstraintBasedLayout),
                    badge: type(of: view).requiresConstraintBasedLayout == UIView.requiresConstraintBasedLayout
                        ? nil : badgeImage),
                row("autoresizingMask", .text(autoresizingMaskText(view.autoresizingMask)),
                    badge: view.autoresizingMask.isEmpty ? nil : badgeImage),
                row("autoresizesSubviews", .bool(view.autoresizesSubviews),
                    badge: view.autoresizesSubviews ? nil : badgeImage),
                row("preservesSuperviewLayoutMargins", .bool(view.preservesSuperviewLayoutMargins),
                    badge: view.preservesSuperviewLayoutMargins ? badgeImage : nil),
                row("insetsLayoutMarginsFromSafeArea", .bool(view.insetsLayoutMarginsFromSafeArea),
                    badge: view.insetsLayoutMarginsFromSafeArea ? nil : badgeImage),
            ])
        }

        private static func traits(_ view: UIView) -> DO.HierarchyBuiltinSection {
            return DO.HierarchyBuiltinSection(title: DO.Text.Hierarchy.sectionTraits, rows: [
                row("traitCollection", .text(String(describing: view.traitCollection))),
                row("semanticContentAttribute",
                    enumKind("UISemanticContentAttribute", raw: Int(view.semanticContentAttribute.rawValue))),
                row("directionalLayoutMargins", .text(directionalInsetsText(view.directionalLayoutMargins))),
                row("effectiveUserInterfaceLayoutDirection",
                    enumKind("UIUserInterfaceLayoutDirection", raw: Int(view.effectiveUserInterfaceLayoutDirection.rawValue))),
            ])
        }

        // MARK: - Helpers

        private static func row(
            _ title: String,
            _ kind: DO.ValueKind,
            detail: String? = nil,
            write: ((DO.ValueKind) -> Void)? = nil,
            badge: UIImage? = nil,
            input: (() -> DO.HierarchyValueInput?)? = nil
        ) -> DO.HierarchyBuiltinRow {
            return DO.HierarchyBuiltinRow(
                title: title,
                detail: detail ?? DO.HierarchyPropertyEngine.shared.displayText(of: kind),
                kind: kind,
                write: write,
                badge: badge,
                input: input
            )
        }

        private static func bool(
            _ title: String,
            _ view: UIView,
            _ keyPath: ReferenceWritableKeyPath<UIView, Bool>
        ) -> DO.HierarchyBuiltinRow {
            return row(title, .bool(view[keyPath: keyPath])) { [weak view] value in
                guard let view = view, case let .bool(isOn) = value else { return }
                view[keyPath: keyPath] = isOn
                refresh(view)
            }
        }

        private static func enumKind(_ table: String, raw: Int) -> DO.ValueKind {
            let name = enumTables[table]?.first { $0.value == raw }?.name ?? "\(raw)"
            return .enumValue(raw: raw, table: table, name: name)
        }

        private static func autoresizingMaskText(_ mask: UIView.AutoresizingMask) -> String {
            if mask.isEmpty { return "none" }

            var parts: [String] = []
            if mask.contains(.flexibleLeftMargin) { parts.append("flexibleLeftMargin") }
            if mask.contains(.flexibleWidth) { parts.append("flexibleWidth") }
            if mask.contains(.flexibleRightMargin) { parts.append("flexibleRightMargin") }
            if mask.contains(.flexibleTopMargin) { parts.append("flexibleTopMargin") }
            if mask.contains(.flexibleHeight) { parts.append("flexibleHeight") }
            if mask.contains(.flexibleBottomMargin) { parts.append("flexibleBottomMargin") }
            return parts.joined(separator: " | ")
        }

        private static func shadowPathText(_ path: CGPath?) -> String {
            guard let path = path else { return "nil" }
            return DO.HierarchyFormatterTool.string(from: path.boundingBox)
        }

        private static func affineCSV(_ values: [Double]) -> String {
            return values.map { DO.HierarchyFormatterTool.preciseFormat(NSNumber(value: $0)) }
                .joined(separator: ",")
        }

        private static func affineTransform(from kind: DO.ValueKind) -> CGAffineTransform? {
            guard case let .text(csv) = kind else { return nil }
            let values = csv.split(separator: ",").compactMap { Double($0) }
            guard values.count == 6 else { return nil }
            return CGAffineTransform(a: values[0], b: values[1], c: values[2],
                                     d: values[3], tx: values[4], ty: values[5])
        }

        private static func matrixText(_ transform: CATransform3D) -> String {
            let values = [transform.m11, transform.m12, transform.m13, transform.m14,
                          transform.m21, transform.m22, transform.m23, transform.m24,
                          transform.m31, transform.m32, transform.m33, transform.m34,
                          transform.m41, transform.m42, transform.m43, transform.m44]
            let format = { (value: CGFloat) in
                DO.HierarchyFormatterTool.preciseFormat(NSNumber(value: Double(value)))
            }
            return stride(from: 0, to: values.count, by: 4)
                .map { index in values[index..<index + 4].map(format).joined(separator: "  ") }
                .joined(separator: "\n")
        }

        private static func transformText(_ transform: CGAffineTransform) -> String {
            let f = { (value: CGFloat) in DO.HierarchyFormatterTool.format(NSNumber(value: Double(value))) }
            return "a \(f(transform.a))  b \(f(transform.b))  c \(f(transform.c))  d \(f(transform.d))"
                + "  tx \(f(transform.tx))  ty \(f(transform.ty))"
        }

        private static func directionalInsetsText(_ insets: NSDirectionalEdgeInsets) -> String {
            let f = { (value: CGFloat) in DO.HierarchyFormatterTool.format(NSNumber(value: Double(value))) }
            return "Top \(f(insets.top))  Leading \(f(insets.leading))"
                + "  Bottom \(f(insets.bottom))  Trailing \(f(insets.trailing))"
        }

        private static func refresh(_ view: UIView) {
            DO.HierarchyLayoutRefresh.refresh(view)
        }
    }
}
