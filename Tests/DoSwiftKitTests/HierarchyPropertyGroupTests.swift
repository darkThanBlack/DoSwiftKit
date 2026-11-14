//
//  HierarchyPropertyGroupTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/06
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class HierarchyPropertyGroupTests: XCTestCase {

    func testStackGroupShowsEnumNamesAndIsEditable() {
        let stack = UIStackView()
        let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: stack)

        let stackSection = models.first { $0.title == "UIStackView" }
        XCTAssertNotNil(stackSection)

        let axis = stackSection?.items.first { $0.title == "axis" }
        XCTAssertEqual(axis?.detailTitle, "horizontal")
        XCTAssertNotNil(axis?.edit)

        let distribution = stackSection?.items.first { $0.title == "distribution" }
        XCTAssertEqual(distribution?.detailTitle, "fill")
        XCTAssertNotNil(distribution?.edit)
    }

    func testTranslatesAutoresizingMaskIsExposed() {
        let view = UIView()
        let rows = DO.HierarchyBuiltinSections.autoLayoutSections(for: view).flatMap(\.rows)
        let row = rows.first { $0.title == "translatesAutoresizingMaskIntoConstraints" }

        XCTAssertEqual(row?.detail, "true")
        XCTAssertNotNil(row?.write)
    }

    func testNonStackViewHasNoStackGroup() {
        let view = UIView()
        let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: view)
        XCTAssertFalse(models.contains { $0.title == "UIStackView" })
    }

    func testScrollGeometryIsReadableAndWritable() {
        let scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: 100, height: 400)

        let section = DO.HierarchyPropertyEngine.shared.categoryModels(for: scrollView)
            .first { $0.title == "UIScrollView" }

        let offset = section?.items.first { $0.title == "contentOffset" }
        XCTAssertNotNil(offset?.edit)

        XCTAssertEqual(section?.items.first { $0.title == "contentSize" }?.detailTitle,
                       "W: 100   H: 400")

        // Derived or gesture-driven values stay read-only.
        XCTAssertNil(section?.items.first { $0.title == "adjustedContentInset" }?.edit)
        XCTAssertNil(section?.items.first { $0.title == "isDragging" }?.edit)
    }

    func testWindowLevelIsExposed() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let section = DO.HierarchyPropertyEngine.shared.categoryModels(for: window)
            .first { $0.title == "UIWindow" }

        XCTAssertNotNil(section?.items.first { $0.title == "windowLevel" }?.edit)
    }

    func testCollectionViewSelectionFlagsAreWritable() {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let section = DO.HierarchyPropertyEngine.shared.categoryModels(for: view)
            .first { $0.title == "UICollectionView" }

        XCTAssertNotNil(section?.items.first { $0.title == "allowsMultipleSelection" }?.edit)
        XCTAssertNotNil(section?.items.first { $0.title == "isPrefetchingEnabled" }?.edit)
    }

    func testDatePickerStyleUsesItsEnumTable() {
        let picker = UIDatePicker()
        let section = DO.HierarchyPropertyEngine.shared.categoryModels(for: picker)
            .first { $0.title == "UIDatePicker" }

        XCTAssertEqual(section?.items.first { $0.title == "preferredDatePickerStyle" }?.detailTitle,
                       "automatic")
    }

    /// One instance per class that has a JSON entry.
    private func inspectableObjects() -> [NSObject] {
        return [
            UILabel(), UIControl(), UIButton(type: .system), UIImageView(), UITextField(),
            UISlider(), UISwitch(), UIActivityIndicatorView(), UIProgressView(), UIPageControl(),
            UIStepper(), UIScrollView(), UITableView(), UITableViewCell(style: .default, reuseIdentifier: nil),
            UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()),
            UICollectionReusableView(), UITextView(), UIDatePicker(), UIPickerView(),
            UINavigationBar(), UIToolbar(), UITabBar(), UISearchBar(),
            UIWindow(frame: .zero), UISegmentedControl(items: ["a"]), UIStackView(),
        ]
    }

    /// UIKit forwards some selectors (`UITextView` / `UISearchBar` input traits) without
    /// registering methods, so KVC raises `NSUnknownKeyException` instead of returning nil.
    func testEveryJSONEntryIsKVCReadable() {
        for object in inspectableObjects() {
            _ = DO.HierarchyPropertyEngine.shared.categoryModels(for: object)
        }
    }

    /// The three segments share one screen, so a JSON key that repeats a code-built row shows
    /// up twice (UILabel's text shadow used to sit next to the layer's shadow).
    func testJSONKeysDoNotRepeatBuiltinRows() {
        let view = UIView()
        view.backgroundColor = .white
        view.tintColor = .systemBlue

        let builtinTitles = Set(
            DO.HierarchyBuiltinSections.propertySections(for: view).flatMap(\.rows).map(\.title)
            + DO.HierarchyBuiltinSections.layerSections(for: view).flatMap(\.rows).map(\.title)
            + DO.HierarchyBuiltinSections.autoLayoutSections(for: view).flatMap(\.rows).map(\.title)
        )

        for object in inspectableObjects() {
            let titles = DO.HierarchyPropertyEngine.shared.categoryModels(for: object)
                .flatMap(\.items).compactMap(\.title)
            let repeated = Set(titles).intersection(builtinTitles).sorted()
            XCTAssertTrue(repeated.isEmpty, "\(type(of: object)) repeats builtin rows: \(repeated)")
        }
    }

    func testSuperclassKeysAreNotRepeatedInSubclassSections() {
        let textView = UITextView()
        let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: textView)

        // `isScrollEnabled` is declared once, on UIScrollView, and inherited by text views.
        let owners = models.filter { section in
            section.items.contains { $0.title == "isScrollEnabled" }
        }
        XCTAssertEqual(owners.map(\.title), ["UIScrollView"])
    }
}
