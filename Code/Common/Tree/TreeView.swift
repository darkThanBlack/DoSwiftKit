//
//  TreeView.swift
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

    /// Generic outline control: one job is to render an expanded tree and report taps.
    /// Expansion, selection and the ancestor path are state owned here; the data source is
    /// a pure query, the delegate supplies content and receives events.
    @objc(DOTreeView)
    final class TreeView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {

        weak var dataSource: DO.TreeViewDataSource? {
            didSet { reloadData() }
        }

        weak var delegate: DO.TreeViewDelegate? {
            didSet { reloadData() }
        }

        var style: DO.TreeViewStyle = DO.TreeViewStyle() {
            didSet { applyStyle(); reloadData() }
        }

        /// Shown on the selected row only, pinned to the viewport's trailing edge.
        var selectionAccessoryTitle: String? {
            didSet { updateAccessory() }
        }

        private let layout = DO.TreeViewLayout()
        private lazy var collectionView: UICollectionView = {
            let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
            view.backgroundColor = .clear
            view.dataSource = self
            view.delegate = self
            view.contentInsetAdjustmentBehavior = .never
            view.showsHorizontalScrollIndicator = true
            view.showsVerticalScrollIndicator = true
            view.alwaysBounceHorizontal = false
            // One gesture drags along one axis only; diagonal drags lock to the dominant one.
            view.isDirectionalLockEnabled = true
            view.register(DO.TreeViewCell.self,
                          forCellWithReuseIdentifier: DO.TreeViewCell.reuseIdentifier)
            return view
        }()

        private let accessoryButton = UIButton(type: .system)

        private var rows: [DO.TreeVisibleRow] = []
        private var rowIndexByID: [AnyHashable: Int] = [:]
        private var expandedIDs: Set<AnyHashable> = []
        private var pathIDs: Set<AnyHashable> = []
        private var selectedID: AnyHashable?

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - State

        func setExpanded(_ expanded: Bool, for id: AnyHashable) {
            if expanded {
                expandedIDs.insert(id)
            } else {
                expandedIDs.remove(id)
            }
        }

        func expand(_ ids: [AnyHashable]) {
            expandedIDs.formUnion(ids)
        }

        func isExpanded(_ id: AnyHashable) -> Bool {
            return expandedIDs.contains(id)
        }

        /// Not named `select`: `UIResponderStandardEditActions` already declares `select:`.
        func selectItem(_ id: AnyHashable?) {
            selectedID = id
        }

        /// Ancestor chain of the focused item, used to tint the guide lines.
        func setPath(_ ids: [AnyHashable]) {
            pathIDs = Set(ids)
        }

        func rowIndex(for id: AnyHashable) -> Int? {
            return rowIndexByID[id]
        }

        var visibleRows: [DO.TreeVisibleRow] {
            return rows
        }

        func reloadData() {
            rows = flattenRows()

            rowIndexByID = [:]
            for (index, row) in rows.enumerated() {
                rowIndexByID[row.id] = index
            }

            layout.update(rowCount: rows.count,
                          contentWidth: contentWidth(),
                          rowHeight: style.rowHeight)
            collectionView.reloadData()
            updateAccessory()
        }

        /// Scrolls the row into view: vertically centered, horizontally so its chevron is
        /// visible (this is the only way to follow a deep row).
        func scroll(to id: AnyHashable, animated: Bool) {
            guard let index = rowIndexByID[id], let row = rows[safe: index] else { return }

            let indexPath = IndexPath(item: index, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)

            let chevronX = style.leading + CGFloat(row.depth) * style.indent
            let maxX = max(0, collectionView.contentSize.width - collectionView.bounds.width)
            let targetX = min(max(0, chevronX - 24), maxX)

            if animated {
                UIView.animate(withDuration: 0.25) {
                    self.collectionView.contentOffset.x = targetX
                }
            } else {
                collectionView.contentOffset.x = targetX
            }
        }

        // MARK: - Layout

        override func layoutSubviews() {
            super.layoutSubviews()
            collectionView.frame = bounds
            updateAccessoryFrame()
        }

        // MARK: - Collection view

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return rows.count
        }

        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DO.TreeViewCell.reuseIdentifier,
                for: indexPath
            )
            if let cell = cell as? DO.TreeViewCell, let row = rows[safe: indexPath.item] {
                cell.update(row: row, style: style)
            }
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: false)
            guard let row = rows[safe: indexPath.item] else { return }
            delegate?.treeView(self, didSelect: row.item)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            updateAccessoryFrame()
        }

        // MARK: - Accessory

        @objc private func accessoryTapped() {
            guard let id = selectedID, let index = rowIndexByID[id],
                  let row = rows[safe: index] else { return }
            delegate?.treeView(self, didTapAccessory: row.item)
        }

        private func updateAccessory() {
            guard let title = selectionAccessoryTitle, !title.isEmpty,
                  let id = selectedID, rowIndexByID[id] != nil else {
                accessoryButton.isHidden = true
                return
            }
            accessoryButton.setTitle(title, for: .normal)
            accessoryButton.isHidden = false
            updateAccessoryFrame()
        }

        private func updateAccessoryFrame() {
            guard let id = selectedID, let index = rowIndexByID[id],
                  let title = selectionAccessoryTitle, !title.isEmpty else {
                accessoryButton.isHidden = true
                return
            }

            let top = CGFloat(index) * style.rowHeight - collectionView.contentOffset.y
            let visible = top + style.rowHeight > 0 && top < bounds.height

            let height = style.accessoryHeight
            let fitting = accessoryButton.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                              height: height))
            let width = max(fitting.width, 44)

            accessoryButton.frame = CGRect(
                x: bounds.width - width - style.accessoryInset,
                y: top + (style.rowHeight - height) / 2,
                width: width,
                height: height
            )
            accessoryButton.isHidden = !visible
        }

        // MARK: - Build

        private func setupViews() {
            addSubview(collectionView)

            accessoryButton.isHidden = true
            accessoryButton.addTarget(self, action: #selector(accessoryTapped), for: .touchUpInside)
            addSubview(accessoryButton)
            applyStyle()
        }

        private func applyStyle() {
            accessoryButton.titleLabel?.font = style.accessoryFont
            accessoryButton.setTitleColor(style.accessoryTextColor, for: .normal)
            accessoryButton.backgroundColor = style.accessoryBackground
            accessoryButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            accessoryButton.layer.cornerRadius = style.accessoryCornerRadius
            accessoryButton.layer.masksToBounds = true
        }

        private func flattenRows() -> [DO.TreeVisibleRow] {
            guard let dataSource = dataSource else { return [] }

            var result: [DO.TreeVisibleRow] = []

            func visit(_ item: Any?, depth: Int) {
                let count = dataSource.treeView(self, numberOfChildrenOf: item)
                guard count > 0 else { return }

                for index in 0..<count {
                    let child = dataSource.treeView(self, childAt: index, of: item)
                    let id = dataSource.treeView(self, idFor: child)
                    let childCount = dataSource.treeView(self, numberOfChildrenOf: child)
                    let itemStyle = delegate?.treeView(self, styleFor: child)
                        ?? DO.TreeItemStyle(title: "")

                    let row = DO.TreeVisibleRow(
                        item: child,
                        id: id,
                        depth: depth,
                        hasChildren: childCount > 0,
                        isExpanded: expandedIDs.contains(id),
                        style: itemStyle,
                        isOnPath: pathIDs.contains(id),
                        isSelected: selectedID == id
                    )
                    result.append(row)

                    if row.isExpanded && childCount > 0 {
                        visit(child, depth: depth + 1)
                    }
                }
            }

            visit(nil, depth: 0)
            return result
        }

        private func contentWidth() -> CGFloat {
            var width: CGFloat = 0
            for row in rows {
                let font = (row.isOnPath || row.isSelected) ? style.pathTitleFont : style.titleFont
                let textWidth = ceil((row.style.title as NSString)
                    .size(withAttributes: [.font: font]).width)
                let rowWidth = style.leading
                    + CGFloat(row.depth) * style.indent
                    + style.chevronWidth
                    + style.contentGap
                    + textWidth
                    + 8
                    + style.trailingPadding
                width = max(width, rowWidth)
            }
            return max(width, bounds.width)
        }
    }
}

private extension Array {

    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
