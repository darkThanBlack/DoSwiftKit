//
//  ConsoleCaptureMirrorTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/09
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class ConsoleCaptureMirrorTests: XCTestCase {

    func testMirrorForwardsBytes() {
        var fds: [Int32] = [-1, -1]
        XCTAssertEqual(pipe(&fds), 0)
        defer {
            close(fds[0])
            close(fds[1])
        }

        let bytes = Array("hello\n".utf8)
        DO.ConsoleCapture.mirror(bytes, count: bytes.count, to: fds[1])

        var buffer = [UInt8](repeating: 0, count: bytes.count)
        let count = read(fds[0], &buffer, buffer.count)

        XCTAssertEqual(count, bytes.count)
        XCTAssertEqual(buffer, bytes)
    }

    func testMirrorIgnoresInvalidDescriptors() {
        DO.ConsoleCapture.mirror([65], count: 1, to: -1)
        DO.ConsoleCapture.mirror([65], count: 1, to: 1_000_000)
    }

    func testMirrorIgnoresEmptyOrOutOfRangeCounts() {
        var fds: [Int32] = [-1, -1]
        XCTAssertEqual(pipe(&fds), 0)
        defer {
            close(fds[0])
            close(fds[1])
        }

        _ = fcntl(fds[0], F_SETFL, O_NONBLOCK)

        DO.ConsoleCapture.mirror([65], count: 0, to: fds[1])
        DO.ConsoleCapture.mirror([65], count: 4, to: fds[1])

        var buffer = [UInt8](repeating: 0, count: 1)
        XCTAssertEqual(read(fds[0], &buffer, buffer.count), -1)
    }
}
