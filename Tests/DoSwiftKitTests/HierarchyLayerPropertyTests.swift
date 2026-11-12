//
//  HierarchyLayerPropertyTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/12
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class HierarchyLayerPropertyTests: XCTestCase {

    private final class ShapeHostView: UIView {
        override class var layerClass: AnyClass { CAShapeLayer.self }
    }

    private final class GradientHostView: UIView {
        override class var layerClass: AnyClass { CAGradientLayer.self }
    }

    private var engine: DO.HierarchyPropertyEngine { DO.HierarchyPropertyEngine.shared }

    func testLayerTreeDrivesSubclassSection() {
        let view = ShapeHostView()
        guard let layer = view.layer as? CAShapeLayer else { return XCTFail("missing shape layer") }

        layer.fillColor = UIColor.red.cgColor
        layer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 10, height: 10)).cgPath

        let section = engine.categoryModels(for: layer).first { $0.title == "CAShapeLayer" }
        XCTAssertNotNil(section)

        let fill = section?.items.first { $0.title == "fillColor" }
        XCTAssertNotNil(fill?.edit)
        XCTAssertNotNil(fill?.detailTitle)

        // String-raw enums show their raw value and stay read-only.
        let lineCap = section?.items.first { $0.title == "lineCap" }
        XCTAssertEqual(lineCap?.detailTitle, "butt")
        XCTAssertNil(lineCap?.edit)

        // CGPath and string enums stay read-only.
        XCTAssertNotNil(section?.items.first { $0.title == "path" })
        XCTAssertNil(section?.items.first { $0.title == "path" }?.edit)
        XCTAssertNil(section?.items.first { $0.title == "fillRule" }?.edit)
    }

    func testLayerWriteConvertsCGColor() {
        let view = ShapeHostView()
        guard let layer = view.layer as? CAShapeLayer else { return XCTFail("missing shape layer") }

        layer.strokeColor = UIColor.red.cgColor

        engine.write(.color(.blue), forKey: "strokeColor", to: layer)
        XCTAssertEqual(layer.strokeColor.map { UIColor(cgColor: $0) }, UIColor.blue)

        engine.write(.double(4), forKey: "lineWidth", to: layer)
        XCTAssertEqual(layer.lineWidth, 4)

        // Declared read-only, so the write must be ignored rather than crash.
        engine.write(.text("square"), forKey: "lineCap", to: layer)
        XCTAssertEqual(layer.lineCap, .butt)
    }

    func testGradientLayerSection() {
        let view = GradientHostView()
        guard let layer = view.layer as? CAGradientLayer else { return XCTFail("missing gradient layer") }

        layer.colors = [UIColor.red.cgColor, UIColor.blue.cgColor]

        let section = engine.categoryModels(for: layer).first { $0.title == "CAGradientLayer" }
        XCTAssertNotNil(section)

        // Arrays have no editor, points and the string enum behave as designed.
        XCTAssertNotNil(section?.items.first { $0.title == "colors" })
        XCTAssertNil(section?.items.first { $0.title == "colors" }?.edit)
        XCTAssertNotNil(section?.items.first { $0.title == "startPoint" }?.edit)
        XCTAssertNotNil(section?.items.first { $0.title == "type" })
        XCTAssertNil(section?.items.first { $0.title == "type" }?.edit)
    }

    func testViewTreeDoesNotSeeLayerEntries() {
        let view = ShapeHostView()
        XCTAssertTrue(engine.categoryModels(for: view).isEmpty,
                      "the view tree has no entry for ShapeHostView")
        XCTAssertTrue(engine.categoryModels(for: UIView().layer).isEmpty,
                      "the layer tree has no entry for plain CALayer")
    }
}
