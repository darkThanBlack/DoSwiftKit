//
//  TreeViewTests.swift
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

final class TreeViewTests: XCTestCase {

    private final class Node {
        let title: String
        let children: [Node]

        init(_ title: String, _ children: [Node] = []) {
            self.title = title
            self.children = children
        }
    }

    private final class Source: DO.TreeViewDataSource {
        let root: Node

        init(root: Node) {
            self.root = root
        }

        func treeView(_ treeView: DO.TreeView, numberOfChildrenOf item: Any?) -> Int {
            guard let node = item as? Node else { return 1 }
            return node.children.count
        }

        func treeView(_ treeView: DO.TreeView, childAt index: Int, of item: Any?) -> Any {
            guard let node = item as? Node else { return root }
            return node.children[index]
        }

        func treeView(_ treeView: DO.TreeView, idFor item: Any) -> AnyHashable {
            return ObjectIdentifier(item as AnyObject)
        }
    }

    private final class Delegate: DO.TreeViewDelegate {
        func treeView(_ treeView: DO.TreeView, styleFor item: Any) -> DO.TreeItemStyle {
            return DO.TreeItemStyle(title: (item as? Node)?.title ?? "")
        }

        func treeView(_ treeView: DO.TreeView, didSelect item: Any) { }
    }

    private func id(of node: Node) -> AnyHashable {
        return ObjectIdentifier(node as AnyObject)
    }

    func testFlattenFollowsExpansion() {
        let d = Node("D")
        let c = Node("C")
        let b = Node("B", [d])
        let a = Node("A", [b, c])

        let source = Source(root: a)
        let treeView = DO.TreeView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let delegate = Delegate()
        treeView.delegate = delegate
        treeView.dataSource = source

        XCTAssertEqual(treeView.visibleRows.map { $0.style.title }, ["A"])

        treeView.setExpanded(true, for: id(of: a))
        treeView.reloadData()
        XCTAssertEqual(treeView.visibleRows.map { $0.style.title }, ["A", "B", "C"])
        XCTAssertEqual(treeView.visibleRows.map { $0.depth }, [0, 1, 1])

        treeView.setExpanded(true, for: id(of: b))
        treeView.reloadData()
        XCTAssertEqual(treeView.visibleRows.map { $0.style.title }, ["A", "B", "D", "C"])
        XCTAssertEqual(treeView.visibleRows.map { $0.depth }, [0, 1, 2, 1])
        XCTAssertEqual(treeView.rowIndex(for: id(of: d)), 2)
    }

    func testPathMarksAncestorsOnly() {
        let d = Node("D")
        let b = Node("B", [d])
        let c = Node("C")
        let a = Node("A", [b, c])

        let source = Source(root: a)
        let treeView = DO.TreeView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let delegate = Delegate()
        treeView.delegate = delegate
        treeView.dataSource = source

        treeView.expand([id(of: a), id(of: b)])
        treeView.setPath([id(of: a), id(of: b)])
        treeView.selectItem(id(of: b))
        treeView.reloadData()

        let rows = treeView.visibleRows
        XCTAssertEqual(rows.map { $0.style.title }, ["A", "B", "D", "C"])

        XCTAssertTrue(rows[0].isOnPath)
        XCTAssertTrue(rows[1].isOnPath)
        XCTAssertTrue(rows[1].isSelected)
        XCTAssertFalse(rows[2].isOnPath)
        XCTAssertFalse(rows[3].isOnPath)
    }

    func testLayoutSizesRowsByContentWidth() {
        let layout = DO.TreeViewLayout()
        layout.update(rowCount: 3, contentWidth: 900, rowHeight: 44)

        XCTAssertEqual(layout.collectionViewContentSize, CGSize(width: 900, height: 132))
        XCTAssertEqual(layout.layoutAttributesForItem(at: IndexPath(item: 2, section: 0))?.frame,
                       CGRect(x: 0, y: 88, width: 900, height: 44))
    }
}
