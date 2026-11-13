//
//  PathBarStyle.swift
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

    /// Breadcrumb appearance. System colors only, so dark mode comes for free.
    enum PathBarStyle {

        static var backgroundColor: UIColor { return .systemBackground }

        /// Current crumb.
        static var currentTextColor: UIColor { return .systemBlue }

        /// Ancestor crumbs.
        static var textColor: UIColor { return .secondaryLabel }

        /// Chevron between crumbs.
        static var separatorColor: UIColor { return .tertiaryLabel }

        static func separatorImage() -> UIImage? { return UIImage(systemName: "chevron.right") }

        /// Crumb text; the current one is bolder.
        static func font(isCurrent: Bool) -> UIFont {
            let font = UIFont.preferredFont(forTextStyle: .footnote)
            guard isCurrent,
                  let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) else {
                return font
            }
            return UIFont(descriptor: descriptor, size: 0)
        }
    }
}
