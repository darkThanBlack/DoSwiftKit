//
//  HierarchyTreeDataSourceTests.swift
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

final class HierarchyTreeDataSourceTests: XCTestCase {

    private final class _PrivateBox: UIView { }

    private func makeHost() -> (root: UIView, label: UILabel) {
        let root = UIView()
        let label = UILabel()
        root.addSubview(label)
        return (root, label)
    }

    func testChainStartsAtTheFocusedView() {
        let (root, label) = makeHost()

        let chain = DO.HierarchyTreeChain.chain(to: label, ignoresPrivateClasses: false)
        XCTAssertTrue(chain.first === label)
        XCTAssertTrue(chain.last === root)
        XCTAssertEqual(chain.count, 2)
    }

    func testPrivateClassesAreSkippedAndChildrenPromoted() {
        let (root, label) = makeHost()
        let box = _PrivateBox()
        root.addSubview(box)
        box.addSubview(label)

        let chain = DO.HierarchyTreeChain.chain(to: label, ignoresPrivateClasses: true)
        XCTAssertEqual(chain.count, 2)
        XCTAssertTrue(chain.first === label)
        XCTAssertTrue(chain.last === root)

        let source = DO.HierarchyTreeDataSource(root: root, ignoresPrivateClasses: true)
        let tree = DO.TreeView()
        XCTAssertEqual(source.treeView(tree, numberOfChildrenOf: nil), 1)
        XCTAssertTrue((source.treeView(tree, childAt: 0, of: nil) as? UIView) === root)
        XCTAssertEqual(source.treeView(tree, numberOfChildrenOf: root), 1)
        XCTAssertTrue((source.treeView(tree, childAt: 0, of: root) as? UIView) === label)
    }

    func testPrivateClassesStayWhenFilterIsOff() {
        let (root, label) = makeHost()
        let box = _PrivateBox()
        root.addSubview(box)
        box.addSubview(label)

        let source = DO.HierarchyTreeDataSource(root: root, ignoresPrivateClasses: false)
        let tree = DO.TreeView()
        XCTAssertEqual(source.treeView(tree, numberOfChildrenOf: root), 1)
        XCTAssertTrue((source.treeView(tree, childAt: 0, of: root) as? UIView) === box)
    }

    func testRootIndexTreatsZeroAsTopmost() {
        XCTAssertEqual(DO.HierarchyTreeChain.rootIndex(chainCount: 0, parentLevels: 0), 0)
        XCTAssertEqual(DO.HierarchyTreeChain.rootIndex(chainCount: 5, parentLevels: 0), 4)
        XCTAssertEqual(DO.HierarchyTreeChain.rootIndex(chainCount: 5, parentLevels: 2), 2)
        XCTAssertEqual(DO.HierarchyTreeChain.rootIndex(chainCount: 5, parentLevels: 99), 4)
    }

    func testIdentityIsTheViewObject() {
        let (root, _) = makeHost()
        let source = DO.HierarchyTreeDataSource(root: root, ignoresPrivateClasses: false)
        let tree = DO.TreeView()

        let a = source.treeView(tree, idFor: root)
        let b = source.treeView(tree, idFor: root)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a, AnyHashable(ObjectIdentifier(root)))
    }
}
