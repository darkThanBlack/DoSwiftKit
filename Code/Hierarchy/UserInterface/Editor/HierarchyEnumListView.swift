//
//  HierarchyEnumListView.swift
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

    @objc(DOHierarchyEnumListView)
    final class HierarchyEnumListView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)? {
            didSet { onValidityChange?(selectedIndex != nil) }
        }

        private let table: String
        private let names: [String]
        private let rawValues: [Int]
        private var selectedIndex: Int?
        private var checkmarks: [UILabel] = []

        convenience init?(table: String, currentRawValue: Int) {
            let options = DO.HierarchyPropertyEngine.shared
                .enumOptions(for: table, currentRawValue: currentRawValue)
            self.init(table: table,
                      names: options.names,
                      rawValues: options.rawValues,
                      currentRawValue: currentRawValue)
        }

        /// Options supplied by the caller, for rows whose enum table lives in code.
        init?(table: String, names: [String], rawValues: [Int], currentRawValue: Int) {
            guard !names.isEmpty, names.count == rawValues.count else { return nil }
            self.table = table
            self.names = names
            self.rawValues = rawValues
            self.selectedIndex = rawValues.firstIndex(of: currentRawValue)
            super.init(frame: .zero)
            setupSubviews()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            guard let index = selectedIndex, rawValues.indices.contains(index) else { return nil }
            return .enumValue(raw: rawValues[index], table: table, name: names[index])
        }

        private func setupSubviews() {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 0

            for (index, name) in names.enumerated() {
                if index > 0 { stack.addArrangedSubview(makeSeparator()) }
                stack.addArrangedSubview(makeRow(index: index, name: name))
            }

            addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            refreshCheckmarks()
        }

        private func makeSeparator() -> UIView {
            let line = UIView()
            line.backgroundColor = .separator
            line.translatesAutoresizingMaskIntoConstraints = false
            line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
            return line
        }

        private func makeRow(index: Int, name: String) -> UIControl {
            let check = UILabel()
            check.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
            check.textColor = .systemBlue
            check.text = "✓"
            checkmarks.append(check)

            let nameLabel = UILabel()
            nameLabel.text = name
            nameLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
            nameLabel.numberOfLines = 0

            let rawLabel = UILabel()
            rawLabel.text = "\(rawValues[index])"
            rawLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            rawLabel.textColor = .secondaryLabel
            rawLabel.setContentHuggingPriority(.required, for: .horizontal)
            rawLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            let content = UIStackView(arrangedSubviews: [check, nameLabel, rawLabel])
            content.axis = .horizontal
            content.alignment = .center
            content.spacing = 10
            content.isUserInteractionEnabled = false

            let row = EnumRowView()
            row.tag = index
            row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
            row.addSubview(content)
            content.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: row.topAnchor, constant: 11),
                content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -11),
                check.widthAnchor.constraint(equalToConstant: 16),
            ])
            return row
        }

        private func refreshCheckmarks() {
            for (index, check) in checkmarks.enumerated() {
                check.alpha = index == selectedIndex ? 1 : 0
            }
        }

        @objc private func rowTapped(_ row: UIControl) {
            selectedIndex = row.tag
            refreshCheckmarks()
            onValidityChange?(true)
        }
    }

    @objc(DOEnumRowView)
    private final class EnumRowView: UIControl {

        override var isHighlighted: Bool {
            didSet { backgroundColor = isHighlighted ? .tertiarySystemFill : .clear }
        }
    }
}
