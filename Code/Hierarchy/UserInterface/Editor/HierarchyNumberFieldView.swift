//
//  HierarchyNumberFieldView.swift
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

    @objc(DOHierarchyNumberFieldView)
    final class HierarchyNumberFieldView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)? {
            didSet { onValidityChange?(readValue() != nil) }
        }

        var onValueChanged: (() -> Void)?

        private let isInteger: Bool

        private let originalValue: Double
        private var isEdited = false

        /// Quick-fill values shown as a single scrollable row under the field. Empty means no strip.
        private let presets: [Double]
        private var chips: [PresetChip] = []

        private static let chipHeight: CGFloat = 28

        init(
            isInteger: Bool,
            step: Double,
            value: Double,
            prominent: Bool = true,
            presets: [Double] = []
        ) {
            self.isInteger = isInteger
            self.originalValue = value
            self.presets = presets
            super.init(frame: .zero)

            field.text = Self.text(for: value, isInteger: isInteger)
            field.font = prominent ? DO.HierarchyEditorStyle.prominentValueFont
                                   : DO.HierarchyEditorStyle.valueFont
            fieldHeight.constant = prominent ? 60 : 40

            stepper.minimumValue = -Self.stepperBound
            stepper.maximumValue = Self.stepperBound
            stepper.stepValue = step
            stepper.value = value

            setupSubviews()
            fieldHeight.isActive = true
            updateValidity()
            updateChipSelection()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            guard let number = currentValue() else { return nil }
            return isInteger ? .int(Int(number)) : .double(number)
        }

        private lazy var fieldHeight = field.heightAnchor.constraint(equalToConstant: 40)

        private lazy var field: UITextField = {
            let field = UITextField()
            field.font = DO.HierarchyEditorStyle.valueFont
            field.textAlignment = .center
            field.backgroundColor = DO.HierarchyEditorStyle.fieldBackground
            field.layer.cornerRadius = DO.HierarchyEditorStyle.fieldRadius
            field.layer.masksToBounds = true
            field.borderStyle = .none

            field.keyboardType = isInteger ? .numbersAndPunctuation : .decimalPad
            DO.HierarchyEditorStyle.disableSmartInput(field)
            field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
            return field
        }()

        private lazy var stepper: UIStepper = {
            let stepper = UIStepper()
            stepper.autorepeat = true
            stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
            return stepper
        }()

        private static let stepperBound = 1e15

        private func setupSubviews() {
            let inputRow = UIStackView(arrangedSubviews: [field, stepper])
            inputRow.axis = .horizontal
            inputRow.alignment = .center
            inputRow.spacing = 12

            let content: UIView
            if presets.isEmpty {
                content = inputRow
            } else {
                let column = UIStackView(arrangedSubviews: [inputRow, makePresetStrip()])
                column.axis = .vertical
                column.alignment = .fill
                column.spacing = 8
                content = column
            }

            addSubview(content)
            content.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: topAnchor),
                content.leadingAnchor.constraint(equalTo: leadingAnchor),
                content.trailingAnchor.constraint(equalTo: trailingAnchor),
                content.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        /// One flat line of chips. Horizontal scrolling keeps the height fixed no matter how many presets.
        private func makePresetStrip() -> UIView {
            let strip = PresetStrip(frame: .zero)
            strip.showsHorizontalScrollIndicator = false
            strip.alwaysBounceHorizontal = false
            strip.alwaysBounceVertical = false

            chips = presets.map(makeChip)

            let row = UIStackView(arrangedSubviews: chips)
            row.axis = .horizontal
            row.alignment = .fill
            row.spacing = 8

            strip.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: strip.contentLayoutGuide.topAnchor),
                row.leadingAnchor.constraint(equalTo: strip.contentLayoutGuide.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: strip.contentLayoutGuide.trailingAnchor),
                row.bottomAnchor.constraint(equalTo: strip.contentLayoutGuide.bottomAnchor),
                row.heightAnchor.constraint(equalTo: strip.frameLayoutGuide.heightAnchor),

                strip.heightAnchor.constraint(equalToConstant: Self.chipHeight),
            ])
            return strip
        }

        private func makeChip(_ value: Double) -> PresetChip {
            let chip = PresetChip()
            chip.value = value
            chip.setTitle(Self.text(for: value, isInteger: isInteger), for: .normal)
            chip.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
            chip.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            chip.layer.cornerRadius = Self.chipHeight / 2
            chip.layer.masksToBounds = true
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chip.heightAnchor.constraint(equalToConstant: Self.chipHeight).isActive = true

            applyChipStyle(chip, selected: false)
            return chip
        }

        private func applyChipStyle(_ chip: PresetChip, selected: Bool) {
            chip.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.13) : .secondarySystemFill
            chip.setTitleColor(selected ? .systemBlue : .label, for: .normal)
            chip.layer.borderWidth = selected ? 1 : 0
            chip.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.4).cgColor
        }

        /// Selection is derived from the current value, so typing a preset by hand highlights it too.
        private func updateChipSelection() {
            guard !chips.isEmpty else { return }
            let current = parsedNumber()
            for chip in chips {
                let selected = current.map { abs($0 - chip.value) < 0.0005 } ?? false
                applyChipStyle(chip, selected: selected)
            }
        }

        @objc private func chipTapped(_ sender: UIButton) {
            guard let chip = sender as? PresetChip else { return }
            applyPreset(chip.value)
        }

        /// Quick-fill path shared by the chip strip. Kept internal so it can be exercised
        /// without a live UIApplication, where `UIControl.sendActions` is a no-op.
        func applyPreset(_ value: Double) {
            isEdited = true
            field.text = Self.text(for: value, isInteger: isInteger)
            stepper.value = value
            updateValidity()
            updateChipSelection()
            onValueChanged?()
        }

        @objc private func fieldChanged() {
            isEdited = true
            if let number = parsedNumber() { stepper.value = number }
            updateValidity()
            updateChipSelection()
            onValueChanged?()
        }

        @objc private func stepperChanged() {
            isEdited = true
            field.text = Self.text(for: stepper.value, isInteger: isInteger)
            updateValidity()
            updateChipSelection()
            onValueChanged?()
        }

        private func parsedNumber() -> Double? {
            guard let text = field.text, !text.isEmpty else { return nil }
            return isInteger ? Int(text).map(Double.init) : Double(text)
        }

        private func updateValidity() {
            onValidityChange?(parsedNumber() != nil)
        }

        private func currentValue() -> Double? {
            guard parsedNumber() != nil else { return nil }
            return isEdited ? parsedNumber() : originalValue
        }

        private static func text(for value: Double, isInteger: Bool) -> String {
            isInteger ? "\(Int(value))" : DO.HierarchyFormatterTool.preciseFormat(NSNumber(value: value))
        }

        /// 28pt chips still get a 44pt tap band: the strip and each chip extend their hit area vertically.
        /// A right edge mask fades the cut-off chip, and only exists while there is more to scroll.
        private final class PresetStrip: UIScrollView {

            private let edgeFade = CAGradientLayer()

            override init(frame: CGRect) {
                super.init(frame: frame)
                edgeFade.startPoint = CGPoint(x: 0, y: 0.5)
                edgeFade.endPoint = CGPoint(x: 1, y: 0.5)
                edgeFade.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
                edgeFade.locations = [0, 0.82, 1]
            }

            required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

            override var contentOffset: CGPoint {
                didSet { updateEdgeFade() }
            }

            override func layoutSubviews() {
                super.layoutSubviews()
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                edgeFade.frame = bounds
                CATransaction.commit()
                updateEdgeFade()
            }

            private func updateEdgeFade() {
                let hasMore = contentSize.width - contentOffset.x > bounds.width + 1
                let mask = hasMore ? edgeFade : nil
                if layer.mask !== mask { layer.mask = mask }
            }

            override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
                return bounds.insetBy(dx: 0, dy: -8).contains(point)
            }
        }

        private final class PresetChip: UIButton {

            var value: Double = 0

            override var isHighlighted: Bool {
                didSet { alpha = isHighlighted ? 0.6 : 1 }
            }

            override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
                return bounds.insetBy(dx: 0, dy: -8).contains(point)
            }
        }
    }
}
