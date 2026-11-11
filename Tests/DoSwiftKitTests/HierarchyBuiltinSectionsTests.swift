//
//  HierarchyBuiltinSectionsTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/09
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class HierarchyBuiltinSectionsTests: XCTestCase {

    func testSegmentSections() {
        let view = UIView()

        XCTAssertEqual(DO.HierarchyBuiltinSections.propertySections(for: view).map(\.title),
                       ["NSObject", "UIView"])
        XCTAssertEqual(DO.HierarchyBuiltinSections.geometrySections(for: view).map(\.title),
                       ["Layer"])
        XCTAssertEqual(DO.HierarchyBuiltinSections.autoLayoutSections(for: view).map(\.title),
                       [DO.Text.Hierarchy.sectionCommon, DO.Text.Hierarchy.sectionDiagnostics,
                        DO.Text.Hierarchy.sectionEffective, DO.Text.Hierarchy.sectionTraits])
    }

    func testAutoLayoutCommonWrites() {
        let view = UIView(frame: CGRect(x: 1, y: 2, width: 30, height: 40))
        let common = DO.HierarchyBuiltinSections.autoLayoutSections(for: view)
            .first { $0.title == DO.Text.Hierarchy.sectionCommon }

        let frame = common?.rows.first { $0.title == "frame" }
        frame?.write?(.frame(CGRect(x: 5, y: 6, width: 50, height: 60)))
        XCTAssertEqual(view.frame, CGRect(x: 5, y: 6, width: 50, height: 60))

        let hugging = common?.rows.first { $0.title == "contentHuggingPriority" }
        hugging?.write?(.point(CGPoint(x: 250, y: 750)))
        XCTAssertEqual(view.contentHuggingPriority(for: .horizontal).rawValue, 250)
        XCTAssertEqual(view.contentHuggingPriority(for: .vertical).rawValue, 750)

        let compression = common?.rows.first { $0.title == "contentCompressionResistancePriority" }
        compression?.write?(.point(CGPoint(x: 750, y: 250)))
        XCTAssertEqual(view.contentCompressionResistancePriority(for: .horizontal).rawValue, 750)
        XCTAssertEqual(view.contentCompressionResistancePriority(for: .vertical).rawValue, 250)
    }

    func testEnumRowAndReadOnlyRows() {
        let view = UIView()
        let appearance = DO.HierarchyBuiltinSections.propertySections(for: view)
            .first { $0.title == "UIView" }

        let mode = appearance?.rows.first { $0.title == "contentMode" }
        XCTAssertEqual(mode?.detail, "scaleToFill")
        mode?.write?(.enumValue(raw: 1, table: "UIViewContentMode", name: "scaleAspectFit"))
        XCTAssertEqual(view.contentMode, .scaleAspectFit)

        let identity = DO.HierarchyBuiltinSections.propertySections(for: view)
            .first { $0.title == "NSObject" }
        XCTAssertNil(identity?.rows.first { $0.title == "class" }?.write)
        XCTAssertNil(identity?.rows.first { $0.title == "description" }?.write)
    }

    func testEffectRowsAndFlags() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        window.layoutIfNeeded()

        let effect = DO.HierarchyBuiltinSections.autoLayoutSections(for: view)
            .first { $0.title == DO.Text.Hierarchy.sectionEffective }

        let margins = effect?.rows.first { $0.title == "layoutMargins" }
        XCTAssertNotNil(margins?.write)

        for title in ["layoutMargins", "layoutMarginsGuide", "safeAreaInsets", "safeAreaLayoutGuide"] {
            XCTAssertNil(effect?.rows.first { $0.title == title }?.badge, title)
        }

        let guide = effect?.rows.first { $0.title == "layoutMarginsGuide" }
        XCTAssertNotNil(guide)
        XCTAssertNil(guide?.write)

        XCTAssertNil(effect?.rows.first { $0.title == "autoresizingMask" }?.badge)

        view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.autoresizingMask = [.flexibleWidth]
        window.layoutIfNeeded()

        let updated = DO.HierarchyBuiltinSections.autoLayoutSections(for: view)
            .first { $0.title == DO.Text.Hierarchy.sectionEffective }
        XCTAssertNil(updated?.rows.first { $0.title == "layoutMarginsGuide" }?.badge)
        XCTAssertNotNil(updated?.rows.first { $0.title == "autoresizingMask" }?.badge)
    }
}
