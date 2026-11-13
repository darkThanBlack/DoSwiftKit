//
//  HierarchyTreeDataSource.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/13
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// Adapts the `UIView` hierarchy to `TreeView`, and keeps the chain rule in one place so
    /// the tree and the breadcrumb always agree on ids and depths.
    enum HierarchyTreeChain {

        /// `0` means no limit: the tree runs up to the topmost ancestor (normally the window).
        /// `N` roots it N levels above the focused view; values past the top clamp there.
        /// The value comes from `HierarchyConfig.treeParentLevels`.
        static func rootIndex(chainCount: Int, parentLevels: Int) -> Int {
            guard chainCount > 0 else { return 0 }
            guard parentLevels > 0 else { return chainCount - 1 }
            return min(parentLevels, chainCount - 1)
        }

        /// Focused view first, topmost superview last. Private classes are skipped when asked,
        /// and their children move up a level — the same rule the data source applies.
        static func chain(to view: UIView, ignoresPrivateClasses: Bool) -> [UIView] {
            var result: [UIView] = []
            var current: UIView? = view
            while let item = current {
                if !(ignoresPrivateClasses && isPrivate(item)) {
                    result.append(item)
                }
                current = item.superview
            }
            return result
        }

        static func isPrivate(_ view: UIView) -> Bool {
            return String(describing: type(of: view)).hasPrefix("_")
        }
    }

    /// One `UIView` per node; identity is the object identifier.
    final class HierarchyTreeDataSource: DO.TreeViewDataSource {

        private let root: UIView
        private let ignoresPrivateClasses: Bool
        private var childCache: [ObjectIdentifier: [UIView]] = [:]

        init(root: UIView, ignoresPrivateClasses: Bool) {
            self.root = root
            self.ignoresPrivateClasses = ignoresPrivateClasses
        }

        func reset() {
            childCache.removeAll()
        }

        func treeView(_ treeView: DO.TreeView, numberOfChildrenOf item: Any?) -> Int {
            guard let view = item as? UIView else { return 1 }
            return children(of: view).count
        }

        func treeView(_ treeView: DO.TreeView, childAt index: Int, of item: Any?) -> Any {
            guard let view = item as? UIView else { return root }
            return children(of: view)[index]
        }

        func treeView(_ treeView: DO.TreeView, idFor item: Any) -> AnyHashable {
            return ObjectIdentifier(item as AnyObject)
        }

        private func children(of view: UIView) -> [UIView] {
            let key = ObjectIdentifier(view)
            if let cached = childCache[key] { return cached }

            var result: [UIView] = []
            for subview in view.subviews {
                if ignoresPrivateClasses && DO.HierarchyTreeChain.isPrivate(subview) {
                    result += children(of: subview)
                } else {
                    result.append(subview)
                }
            }
            childCache[key] = result
            return result
        }
    }

    /// Minimum the path bar reads: the class name.
    struct HierarchyPathNode: DO.PathNode {

        let view: UIView

        var nodeName: String? {
            return String(describing: type(of: view))
        }
    }
}
