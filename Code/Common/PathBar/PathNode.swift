//
//  PathNode.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/13
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// Minimum the path bar needs: a display name. No id — identity stays in the business
    /// model, which the browser hands back untouched for you to cast.
    protocol PathNode {

        /// nil or empty = nothing to show (path bar draws a placeholder, the row hides it).
        var nodeName: String? { get }
    }
}
