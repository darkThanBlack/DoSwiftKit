//
//  HierarchySettingsTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/13
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class HierarchySettingsTests: XCTestCase {

    func testTreeParentLevelsDefaultsToZero() {
        XCTAssertEqual(DO.HierarchyConfig().treeParentLevels, 0)
    }

    func testConfigDecodesWithoutTheTreeLevelKey() throws {
        let legacy = #"{"isColorPickEnabled":false,"isIgnorePrivateClass":false}"#.data(using: .utf8)!
        let config = try JSONDecoder().decode(DO.HierarchyConfig.self, from: legacy)

        XCTAssertFalse(config.isColorPickEnabled)
        XCTAssertFalse(config.isIgnorePrivateClass)
        XCTAssertEqual(config.treeParentLevels, 0)
    }

    func testTreeParentLevelsRoundTrips() throws {
        var config = DO.HierarchyConfig()
        config.treeParentLevels = 3

        let data = try JSONEncoder().encode(config)
        XCTAssertEqual(try JSONDecoder().decode(DO.HierarchyConfig.self, from: data).treeParentLevels, 3)
    }

    func testSettingsExposeTreeParentLevels() {
        let controller = DO.HierarchySettingViewController()
        controller.loadViewIfNeeded()

        let group = controller.sections.first { $0.title == DO.Text.Hierarchy.viewHierarchyGroup }
        XCTAssertEqual(group?.rows.count, 2)
        XCTAssertTrue(group?.rows.last?.cellClass == DO.SelectorCell.self)
    }
}
