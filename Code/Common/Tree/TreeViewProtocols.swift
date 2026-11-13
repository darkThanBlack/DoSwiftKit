//
//  TreeViewProtocols.swift
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

    /// Pure structural source. No state, no UI: the control keeps expansion, selection and path.
    protocol TreeViewDataSource: AnyObject {

        /// `item == nil` is the virtual root; return 0 when there is nothing to show.
        func treeView(_ treeView: DO.TreeView, numberOfChildrenOf item: Any?) -> Int

        func treeView(_ treeView: DO.TreeView, childAt index: Int, of item: Any?) -> Any

        /// Stable identity, used for expansion, selection and the path.
        func treeView(_ treeView: DO.TreeView, idFor item: Any) -> AnyHashable
    }

    protocol TreeViewDelegate: AnyObject {

        /// Content only; indentation, guides and state are the control's job.
        func treeView(_ treeView: DO.TreeView, styleFor item: Any) -> DO.TreeItemStyle

        /// The whole row was tapped. The control does not expand by itself.
        func treeView(_ treeView: DO.TreeView, didSelect item: Any)

        func treeView(_ treeView: DO.TreeView, didToggle item: Any, expanded: Bool)

        /// The floating accessory button was tapped.
        func treeView(_ treeView: DO.TreeView, didTapAccessory item: Any)
    }
}

extension DO.TreeViewDelegate {

    func treeView(_ treeView: DO.TreeView, didToggle item: Any, expanded: Bool) { }
    func treeView(_ treeView: DO.TreeView, didTapAccessory item: Any) { }
}
