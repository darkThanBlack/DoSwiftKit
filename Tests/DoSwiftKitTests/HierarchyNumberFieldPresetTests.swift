//
//  HierarchyNumberFieldPresetTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/11
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class HierarchyNumberFieldPresetTests: XCTestCase {

    private func descendants(of view: UIView) -> [UIView] {
        var result: [UIView] = []
        for subview in view.subviews {
            result.append(subview)
            result += descendants(of: subview)
        }
        return result
    }

    private func buttons(in view: UIView) -> [UIButton] {
        return descendants(of: view).compactMap { $0 as? UIButton }
    }

    private func titles(in view: UIView) -> [String] {
        return buttons(in: view).map { $0.title(for: .normal) ?? "" }
    }

    func testChipsFollowPresets() {
        let field = DO.HierarchyNumberFieldView(isInteger: true, step: 50, value: 750,
                                                prominent: false, presets: [1000, 750, 250, 50])
        XCTAssertEqual(titles(in: field), ["1000", "750", "250", "50"])
    }

    func testNoPresetsMeansNoStrip() {
        let field = DO.HierarchyNumberFieldView(isInteger: true, step: 50, value: 750)
        XCTAssertTrue(buttons(in: field).isEmpty)
    }

    func testChipIsWiredToTheField() {
        let field = DO.HierarchyNumberFieldView(isInteger: true, step: 50, value: 750,
                                                prominent: false, presets: [1000, 750, 250, 50])
        let actions = buttons(in: field)
            .flatMap { $0.actions(forTarget: field, forControlEvent: .touchUpInside) ?? [] }
        XCTAssertEqual(actions.count, 4)
        XCTAssertEqual(Set(actions), ["chipTapped:"])
    }

    func testPresetFillsIntegerField() {
        let field = DO.HierarchyNumberFieldView(isInteger: true, step: 50, value: 750,
                                                prominent: false, presets: [1000, 750, 250, 50])

        var changed = 0
        field.onValueChanged = { changed += 1 }

        field.applyPreset(250)

        guard case let .int(value)? = field.readValue() else {
            return XCTFail("preset produced no value")
        }
        XCTAssertEqual(value, 250)
        XCTAssertEqual(changed, 1)
    }

    func testPresetFillsDecimalField() {
        let field = DO.HierarchyNumberFieldView(isInteger: false, step: 1, value: 0,
                                                prominent: false, presets: [0, 8, 16, -8])

        field.applyPreset(-8)

        guard case let .double(value)? = field.readValue() else {
            return XCTFail("preset produced no value")
        }
        XCTAssertEqual(value, -8, accuracy: 0.0005)
    }

    func testSelectionFollowsTheValue() {
        let field = DO.HierarchyNumberFieldView(isInteger: true, step: 50, value: 750,
                                                prominent: false, presets: [1000, 750, 250, 50])

        field.applyPreset(250)

        for chip in buttons(in: field) {
            let selected = chip.titleColor(for: .normal) == UIColor.systemBlue
            XCTAssertEqual(selected, chip.title(for: .normal) == "250", chip.title(for: .normal) ?? "")
        }
    }

    func testGridSharesOnePresetList() {
        let grid = DO.HierarchyNumberGridView(
            labels: ["horizontal", "vertical"],
            values: [750, 750],
            presets: [1000, 750, 250, 50]
        ) {
            .point(CGPoint(x: $0[0], y: $0[1]))
        }

        XCTAssertEqual(buttons(in: grid).count, 8)

        let fields = descendants(of: grid).compactMap { $0 as? DO.HierarchyNumberFieldView }
        XCTAssertEqual(fields.count, 2)

        fields[0].applyPreset(250)

        guard case let .point(point)? = grid.readValue() else {
            return XCTFail("grid produced no value")
        }
        XCTAssertEqual(point.x, 250, accuracy: 0.0005)
        XCTAssertEqual(point.y, 750, accuracy: 0.0005)
    }

    func testChipsKeepOneScrollableRow() {
        let field = DO.HierarchyNumberFieldView(isInteger: false, step: 1, value: 0, prominent: false,
                                                presets: [0, 1, 10, 100, -1, -10, 1000, -1000])
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 240, height: 180))
        host.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: host.topAnchor, constant: 20),
            field.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 20),
            field.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -20),
        ])
        host.layoutIfNeeded()

        // 40pt input row + 8pt gap + 28pt chips.
        XCTAssertEqual(field.bounds.height, 76, accuracy: 0.5)

        let strips = descendants(of: field).compactMap { $0 as? UIScrollView }
        XCTAssertTrue(strips.contains { $0.bounds.height == 28 && $0.contentSize.width > $0.bounds.width },
                      "chips should overflow horizontally instead of wrapping")
    }

    func testPriorityRowsExposePresets() {
        let view = UIView()
        let common = DO.HierarchyBuiltinSections.autoLayoutSections(for: view)
            .first { $0.title == DO.Text.Hierarchy.sectionCommon }
        let hugging = common?.rows.first { $0.title == "contentHuggingPriority" }

        guard let input = hugging?.input?() else { return XCTFail("missing input") }
        let priorityTitles = ["1000", "750", "250", "50", "25"]
        XCTAssertEqual(titles(in: input), priorityTitles + priorityTitles)
    }
}
