//
//  HierarchyDetailViewController.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    @objc(DOHierarchyDetailViewController)
    class HierarchyDetailViewController: DO.SectionTableViewController {

        weak var selectView: UIView?

        private enum Tab: Int {
            case properties
            case layer
            case autoLayout
        }

        private var selectedTab: Tab = .properties

        private lazy var segments: UISegmentedControl = {
            let control = UISegmentedControl(items: [DO.Text.Hierarchy.segmentProperties,
                                                     DO.Text.Hierarchy.segmentLayer,
                                                     DO.Text.Hierarchy.segmentAutoLayout])
            control.selectedSegmentIndex = Tab.properties.rawValue
            control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
            return control
        }()

        override func viewDidLoad() {
            super.viewDidLoad()

            title = DO.Text.Hierarchy.detailTitle
            navigationItem.titleView = segments

            loadData()

        }

        @objc private func segmentChanged() {
            selectedTab = Tab(rawValue: segments.selectedSegmentIndex) ?? .properties
            loadData()
        }

        private func loadData() {
            guard let view = selectView else { return }

            switch selectedTab {
            case .properties:
                var result = DO.HierarchyBuiltinSections.propertySections(for: view)
                    .map { builtinSection($0) }
                result += DO.HierarchyPropertyEngine.shared.categoryModels(for: view)
                    .map { jsonSection($0) }
                // Most-derived first: subclass, then UIView, then NSObject.
                sections = Array(result.reversed())

            case .layer:
                sections = DO.HierarchyBuiltinSections.layerSections(for: view)
                    .map { builtinSection($0) }

            case .autoLayout:
                var result = DO.HierarchyBuiltinSections.autoLayoutSections(for: view)
                    .map { builtinSection($0) }
                result.insert(constraintSection(for: view), at: min(1, result.count))
                sections = result
            }
        }

        private func builtinSection(_ section: DO.HierarchyBuiltinSection) -> Section {
            return Section(title: section.title, rows: section.rows.map { row(for: $0) })
        }

        private func jsonSection(_ model: DO.HierarchyCategoryModel) -> Section {
            return Section(title: model.title, rows: model.items.map { row(for: $0) })
        }

        private func constraintSection(for view: UIView) -> Section {
            let engine = DO.HierarchyConstraintEngine.shared
            let constraints = engine.constraints(involving: view)

            let rows: [Row] = constraints.map { constraint in
                let summary = engine.summary(for: constraint, from: view)
                return Row(
                    cellClass: DO.SelectorCell.self,
                    onTrigger: { [weak self, weak view] _ in
                        guard let view = view else { return }
                        self?.presentConstraintEditor(constraint, view: view)
                    }
                ) { cell in
                    cell.titleNumberOfLines = 0
                    cell.update(title: summary.fullText, detail: nil)
                }
            }

            return Section(
                title: DO.Text.Hierarchy.sectionConstraints,
                footer: constraints.isEmpty ? DO.Text.Hierarchy.constraintEmpty : nil,
                rows: rows
            )
        }

        // MARK: - Builtin rows (code-backed, direct property access)

        private func row(for item: DO.HierarchyBuiltinRow) -> Row {
            guard let write = item.write else {
                return Row(cellClass: DO.KeyValueCell.self) { cell in
                    cell.update(title: item.title, detail: item.detail, rightImage: item.badge)
                }
            }

            if case .bool(let isOn) = item.kind {
                return Row(
                    cellClass: DO.ToggleCell.self,
                    onTrigger: { [weak self] cell in
                        write(.bool(cell.isOn))
                        self?.loadData()
                    }
                ) { cell in
                    cell.update(title: item.title, detail: item.detail, isOn: isOn)
                }
            }

            return Row(
                cellClass: DO.SelectorCell.self,
                onTrigger: { [weak self] _ in
                    guard let self = self else { return }
                    let input = item.input?() ?? self.makeInput(for: item.kind)
                    self.presentEditor(title: item.title,
                                       kind: item.kind,
                                       input: input,
                                       onCommit: write)
                }
            ) { cell in
                cell.update(title: item.title, detail: item.detail)
            }
        }

        private func presentEditor(
            title: String,
            kind: DO.ValueKind,
            input: DO.HierarchyValueInput?,
            onCommit: @escaping (DO.ValueKind) -> Void
        ) {
            guard let input = input else { return }

            let card = DO.HierarchyEditorCard(key: title, kind: kind, input: input) { [weak self] value in
                onCommit(value)
                self?.loadData()
            }
            present(card, animated: true)
        }

        private func makeInput(for kind: DO.ValueKind) -> DO.HierarchyValueInput? {
            if case let .enumValue(raw, table, _) = kind,
               let options = DO.HierarchyBuiltinSections.enumTables[table] {
                return DO.HierarchyEnumListView(table: table,
                                                names: options.map(\.name),
                                                rawValues: options.map(\.value),
                                                currentRawValue: raw)
            }
            return DO.HierarchyValueInputFactory.make(for: kind)
        }

        private func presentConstraintEditor(_ constraint: NSLayoutConstraint, view: UIView) {
            let summary = DO.HierarchyConstraintEngine.shared.summary(for: constraint, from: view)
            let card = DO.HierarchyConstraintEditorCard(
                constraint: constraint,
                summary: summary,
                targetView: view
            ) { [weak self] in
                self?.loadData()
            }
            present(card, animated: true)
        }

        private func row(for item: DO.HierarchyCellModel) -> Row {
            guard let edit = item.edit else {
                return Row(cellClass: DO.KeyValueCell.self) { cell in
                    cell.update(item)
                    cell.separatorInset = item.separatorInsets
                }
            }

            switch edit.kind {
            case .bool(let isOn):
                return Row(
                    cellClass: DO.ToggleCell.self,
                    onTrigger: { [weak self] cell in self?.writeToggle(edit, isOn: cell.isOn) }
                ) { cell in
                    cell.update(title: item.title, detail: item.detailTitle, isOn: isOn)
                    cell.separatorInset = item.separatorInsets
                }

            default:
                return Row(
                    cellClass: DO.SelectorCell.self,
                    onTrigger: { [weak self] _ in self?.presentEditor(edit) }
                ) { cell in
                    cell.update(title: item.title, detail: item.detailTitle)
                    cell.separatorInset = item.separatorInsets
                }
            }
        }

        private func writeToggle(_ edit: DO.HierarchyEditDescriptor, isOn: Bool) {
            guard let view = selectView else { return }
            DO.HierarchyPropertyEngine.shared.write(.bool(isOn), forKey: edit.key, to: view)
            loadData()
        }

        private func presentEditor(_ edit: DO.HierarchyEditDescriptor) {
            guard let view = selectView,
                  let input = DO.HierarchyValueInputFactory.make(for: edit.kind) else { return }

            let card = DO.HierarchyEditorCard(key: edit.key, kind: edit.kind, input: input) { [weak self, weak view] value in
                guard let view = view else { return }
                DO.HierarchyPropertyEngine.shared.write(value, forKey: edit.key, to: view)
                self?.loadData()
            }
            present(card, animated: true)
        }
    }
}
