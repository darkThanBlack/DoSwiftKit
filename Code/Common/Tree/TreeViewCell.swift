//
//  TreeViewCell.swift
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

    /// Default row: guide lines, chevron, title, hidden badge. The accessory button is a
    /// floating overlay owned by `TreeView`, so it stays at the viewport edge while scrolling.
    @objc(DOTreeViewCell)
    final class TreeViewCell: UICollectionViewCell {

        static let reuseIdentifier = "DOTreeViewCell"

        private let guideLayer = CAShapeLayer()
        private let selectionBar = UIView()
        private let chevronView = UIImageView()
        private let titleLabel = UILabel()

        private var row: DO.TreeVisibleRow?
        private var style: DO.TreeViewStyle = .init()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(row: DO.TreeVisibleRow, style: DO.TreeViewStyle) {
            self.row = row
            self.style = style

            titleLabel.text = row.style.title
            titleLabel.font = (row.isOnPath || row.isSelected) ? style.pathTitleFont : style.titleFont
            titleLabel.textColor = row.isSelected
                ? style.selectedTitleColor
                : (row.isOnPath ? style.pathTitleColor : style.titleColor)
            titleLabel.alpha = row.style.isDimmed ? style.dimmedAlpha : 1

            chevronView.isHidden = !row.hasChildren
            chevronView.tintColor = style.chevronColor
            chevronView.transform = row.isExpanded ? CGAffineTransform(rotationAngle: .pi / 2) : .identity

            contentView.backgroundColor = row.isSelected ? style.selectionColor : .clear
            selectionBar.isHidden = !row.isSelected
            selectionBar.backgroundColor = style.selectionBarColor

            guideLayer.strokeColor = style.guideColor.cgColor
            guideLayer.lineWidth = style.guideWidth
            guideLayer.lineDashPattern = style.guideDashPattern

            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard let row = row else { return }

            let leading = style.leading + CGFloat(row.depth) * style.indent
            chevronView.frame = CGRect(x: leading,
                                       y: (bounds.height - style.chevronWidth) / 2,
                                       width: style.chevronWidth,
                                       height: style.chevronWidth)

            let font = titleLabel.font ?? style.titleFont
            let titleWidth = ceil((row.style.title as NSString).size(withAttributes: [.font: font]).width)
            let titleHeight = ceil(font.lineHeight)
            let x = leading + style.chevronWidth + style.contentGap
            titleLabel.frame = CGRect(x: x, y: (bounds.height - titleHeight) / 2,
                                      width: titleWidth, height: titleHeight)

            selectionBar.frame = CGRect(x: 0, y: 8,
                                        width: style.selectionBarWidth,
                                        height: max(0, bounds.height - 16))

            let guides = UIBezierPath()
            for level in 0..<row.depth {
                let x = style.leading + CGFloat(level) * style.indent + style.chevronWidth / 2
                guides.move(to: CGPoint(x: x, y: 0))
                guides.addLine(to: CGPoint(x: x, y: bounds.height))
            }
            guideLayer.frame = bounds
            guideLayer.path = guides.cgPath
        }

        private func setupViews() {
            contentView.backgroundColor = .clear

            guideLayer.fillColor = UIColor.clear.cgColor
            contentView.layer.addSublayer(guideLayer)

            selectionBar.layer.cornerRadius = style.selectionBarWidth / 2
            contentView.addSubview(selectionBar)

            let configuration = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
            chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: configuration)
            chevronView.contentMode = .center
            contentView.addSubview(chevronView)

            titleLabel.numberOfLines = 1
            titleLabel.lineBreakMode = .byClipping
            contentView.addSubview(titleLabel)
        }
    }
}
