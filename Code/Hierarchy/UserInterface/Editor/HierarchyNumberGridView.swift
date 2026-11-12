//
//  HierarchyNumberGridView.swift
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

    @objc(DOHierarchyNumberGridView)
    final class HierarchyNumberGridView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)?

        private let fields: [DO.HierarchyNumberFieldView]
        private let compose: ([Double]) -> DO.ValueKind

        /// `presets` is one list shared by every field: each row renders the same chip strip,
        /// and there is deliberately no per-row preset list to line up with `labels`.
        init(
            labels: [String],
            values: [Double],
            presets: [Double] = [],
            compose: @escaping ([Double]) -> DO.ValueKind
        ) {
            self.compose = compose
            self.fields = values.map {
                DO.HierarchyNumberFieldView(isInteger: false, step: 1, value: $0,
                                            prominent: false, presets: presets)
            }
            super.init(frame: .zero)
            setupSubviews(labels: labels)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            guard let numbers = currentValues() else { return nil }
            return compose(numbers)
        }

        private func setupSubviews(labels: [String]) {
            let rows: [UIView] = zip(labels, fields).map { label, field in
                let name = DO.HierarchyEditorStyle.makeLabel(label)
                name.setContentHuggingPriority(.required, for: .horizontal)
                name.setContentCompressionResistancePriority(.required, for: .horizontal)

                let row = UIStackView(arrangedSubviews: [name, field])
                row.axis = .horizontal
                // Top aligned: a field with a preset strip below is taller than one input row,
                // and the label should stay level with the input, not the whole column.
                row.alignment = .top
                row.spacing = 12

                // 76 fits the longest label in use ("horizontal") at 12pt SF Mono.
                name.widthAnchor.constraint(equalToConstant: 76).isActive = true
                name.heightAnchor.constraint(equalToConstant: 40).isActive = true
                return row
            }

            let stack = UIStackView(arrangedSubviews: rows)
            stack.axis = .vertical
            stack.spacing = DO.HierarchyEditorStyle.rowGap

            addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            for field in fields {
                field.onValueChanged = { [weak self] in self?.changed() }
                field.onValidityChange = { [weak self] _ in self?.changed() }
            }
        }

        private func currentValues() -> [Double]? {
            var numbers: [Double] = []
            for field in fields {
                guard case let .double(number)? = field.readValue() else { return nil }
                numbers.append(number)
            }
            return numbers
        }

        private func changed() {
            let values = currentValues()
            onValidityChange?(values != nil)
        }

    }
}
