//
//  HierarchyTreeViewController.swift
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

    /// Full-screen tree picker. The row focuses a view and toggles it; the floating accessory
    /// confirms and returns. The breadcrumb always shows the full path and confirms on tap.
    @objc(DOHierarchyTreeViewController)
    final class HierarchyTreeViewController: UIViewController,
        DO.TreeViewDelegate, DO.PathBarViewDataSource, DO.PathBarViewDelegate {

        var onConfirm: ((UIView) -> Void)?

        private let config = DO.HierarchyPlugin.shared.config
        private var focused: UIView
        private let treeView = DO.TreeView()
        private let pathBar = DO.PathBarView()
        private var dataSource: DO.HierarchyTreeDataSource?

        init(focused: UIView) {
            self.focused = focused
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .systemBackground
            title = DO.Text.Hierarchy.treeTitle
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            )

            let chain = currentChain()
            let rootIndex = DO.HierarchyTreeChain.rootIndex(
                chainCount: chain.count,
                parentLevels: config.treeParentLevels
            )
            let root = chain[rootIndex]
            let dataSource = DO.HierarchyTreeDataSource(
                root: root,
                ignoresPrivateClasses: config.isIgnorePrivateClass
            )
            self.dataSource = dataSource

            setupLayout()

            treeView.dataSource = dataSource
            treeView.delegate = self
            treeView.selectionAccessoryTitle = DO.Text.Hierarchy.focus
            pathBar.dataSource = self
            pathBar.delegate = self

            reloadTree()
        }

        // MARK: - Layout

        private func setupLayout() {
            let separator = UIView()
            separator.backgroundColor = .separator

            [pathBar, separator, treeView].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            }

            NSLayoutConstraint.activate([
                pathBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                pathBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pathBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pathBar.heightAnchor.constraint(equalToConstant: 38),

                separator.topAnchor.constraint(equalTo: pathBar.bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

                treeView.topAnchor.constraint(equalTo: separator.bottomAnchor),
                treeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                treeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                treeView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }

        // MARK: - State

        private func currentChain() -> [UIView] {
            return DO.HierarchyTreeChain.chain(
                to: focused,
                ignoresPrivateClasses: config.isIgnorePrivateClass
            )
        }

        private func reloadTree() {
            let chain = currentChain()
            let ids = chain.map { ObjectIdentifier($0) }
            let focusID = ObjectIdentifier(focused)

            treeView.setPath(ids)
            treeView.expand(ids)
            treeView.selectItem(focusID)
            treeView.reloadData()
            view.layoutIfNeeded()
            treeView.scroll(to: focusID, animated: false)
            pathBar.reloadData()
        }

        private func confirm(_ view: UIView) {
            onConfirm?(view)
            dismiss(animated: true)
        }

        @objc private func closeTapped() {
            dismiss(animated: true)
        }

        // MARK: - TreeViewDelegate

        func treeView(_ treeView: DO.TreeView, styleFor item: Any) -> DO.TreeItemStyle {
            guard let view = item as? UIView else { return DO.TreeItemStyle(title: "") }
            let isDimmed = view.isHidden || view.alpha < 0.01
            return DO.TreeItemStyle(title: String(describing: type(of: view)), isDimmed: isDimmed)
        }

        func treeView(_ treeView: DO.TreeView, didSelect item: Any) {
            guard let view = item as? UIView else { return }

            focused = view
            let id = ObjectIdentifier(view)
            treeView.selectItem(id)
            treeView.setExpanded(!treeView.isExpanded(id), for: id)
            treeView.setPath(currentChain().map { ObjectIdentifier($0) })
            treeView.reloadData()
            pathBar.reloadData()
        }

        func treeView(_ treeView: DO.TreeView, didTapAccessory item: Any) {
            guard let view = item as? UIView else { return }
            confirm(view)
        }

        // MARK: - PathBar

        private func orderedChain() -> [UIView] {
            return Array(currentChain().reversed())
        }

        func pathBarItemNumbers(_ bar: DO.PathBarView) -> Int {
            return orderedChain().count
        }

        func pathBar(_ bar: DO.PathBarView, itemFor index: Int) -> any DO.PathNode {
            return DO.HierarchyPathNode(view: orderedChain()[index])
        }

        func pathBar(_ bar: DO.PathBarView, canSelectAt index: Int) -> Bool {
            return index != orderedChain().count - 1
        }

        func pathBar(_ bar: DO.PathBarView, didSelectAt index: Int) {
            let chain = orderedChain()
            guard chain.indices.contains(index) else { return }
            confirm(chain[index])
        }
    }
}
