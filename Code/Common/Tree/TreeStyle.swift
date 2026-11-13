//
//  TreeStyle.swift
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

    /// What the delegate fills for one row. Layout, indentation and state stay in the control.
    struct TreeItemStyle {
        var title: String
        var isDimmed: Bool

        init(title: String, isDimmed: Bool = false) {
            self.title = title
            self.isDimmed = isDimmed
        }
    }

    /// One visible row, produced by flattening the expanded tree.
    struct TreeVisibleRow {
        let item: Any
        let id: AnyHashable
        let depth: Int
        let hasChildren: Bool
        let isExpanded: Bool
        let style: DO.TreeItemStyle

        let isOnPath: Bool
        let isSelected: Bool
    }

    struct TreeViewStyle {
        var rowHeight: CGFloat = 44
        var indent: CGFloat = 14
        var leading: CGFloat = 10
        var chevronWidth: CGFloat = 20
        var contentGap: CGFloat = 6
        var accessoryInset: CGFloat = 8
        var accessoryHeight: CGFloat = 28
        var trailingPadding: CGFloat = 76

        var titleFont: UIFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
        var pathTitleFont: UIFont = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        var titleColor: UIColor = .label
        var pathTitleColor: UIColor = .systemBlue
        var selectedTitleColor: UIColor = .systemBlue
        var dimmedAlpha: CGFloat = 0.45

        var guideColor: UIColor = UIColor.label.withAlphaComponent(0.16)
        var guideWidth: CGFloat = 1
        var guideDashPattern: [NSNumber] = [2, 2]

        var chevronColor: UIColor = .secondaryLabel

        var selectionColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.12)
        var selectionBarColor: UIColor = .systemBlue
        var selectionBarWidth: CGFloat = 3

        var accessoryBackground: UIColor = .systemBlue
        var accessoryTextColor: UIColor = .white
        var accessoryFont: UIFont = .systemFont(ofSize: 12, weight: .semibold)
        var accessoryCornerRadius: CGFloat = 14
    }
}
