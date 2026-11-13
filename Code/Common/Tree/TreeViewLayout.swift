//
//  TreeViewLayout.swift
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

    /// Fixed-height, single-section, full-content-width rows. The content width may exceed the
    /// viewport, which is how the collection view gets horizontal scrolling for deep trees.
    @objc(DOTreeViewLayout)
    final class TreeViewLayout: UICollectionViewLayout {

        private(set) var contentWidth: CGFloat = 0
        private var rowCount = 0
        private var rowHeight: CGFloat = 44

        func update(rowCount: Int, contentWidth: CGFloat, rowHeight: CGFloat) {
            self.rowCount = rowCount
            self.contentWidth = contentWidth
            self.rowHeight = rowHeight
            invalidateLayout()
        }

        override var collectionViewContentSize: CGSize {
            return CGSize(width: contentWidth, height: CGFloat(rowCount) * rowHeight)
        }

        override func prepare() {
            super.prepare()
            guard let collectionView = collectionView, rowHeight > 0 else { return }
            contentWidth = max(contentWidth, collectionView.bounds.width)
        }

        override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
            guard rowCount > 0, rowHeight > 0 else { return [] }
            let start = max(0, Int(floor(rect.minY / rowHeight)))
            let end = min(rowCount - 1, Int(floor(rect.maxY / rowHeight)))
            guard start <= end else { return [] }
            return (start...end).map { attributes(for: $0) }
        }

        override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
            guard indexPath.item >= 0, indexPath.item < rowCount else { return nil }
            return attributes(for: indexPath.item)
        }

        override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
            return false
        }

        private func attributes(for index: Int) -> UICollectionViewLayoutAttributes {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attributes.frame = CGRect(x: 0, y: CGFloat(index) * rowHeight,
                                      width: contentWidth, height: rowHeight)
            return attributes
        }
    }
}
