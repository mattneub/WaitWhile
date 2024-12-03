import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WaitWhileMacros)
import WaitWhileMacros

let testMacros: [String: Macro.Type] = [
    "while": WaitWhileMacro.self,
]
#endif

final class WaitWhileTests: XCTestCase {
    func testMacroWithTimeout() throws {
        #if canImport(WaitWhileMacros)
        assertMacroExpansion(
            """
            #while(1 == 1, timeout: 1_000_000_000)
            """,
            expandedSource: """
            { () -> Void in
                var timeoutTask: Task<(), any Error>? = nil
                var timedOut = false
                let mainTask = Task {
                    while 1 == 1 {
                        await Task.yield()
                        try Task.checkCancellation()
                    }
                    timeoutTask?.cancel()
                }
                timeoutTask = Task.detached {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    timedOut = true
                    mainTask.cancel()
                }
                _ = await mainTask.result
                if timedOut {
                    #if canImport(Testing)
                    Issue.record("timed out")
                    #endif
                }
            }()
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithoutTimeout() throws {
        #if canImport(WaitWhileMacros)
        assertMacroExpansion(
            """
            #while(1 == 1)
            """,
            expandedSource: """
            { () -> Void in
                var timeoutTask: Task<(), any Error>? = nil
                var timedOut = false
                let mainTask = Task {
                    while 1 == 1 {
                        await Task.yield()
                        try Task.checkCancellation()
                    }
                    timeoutTask?.cancel()
                }
                timeoutTask = Task.detached {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    timedOut = true
                    mainTask.cancel()
                }
                _ = await mainTask.result
                if timedOut {
                    #if canImport(Testing)
                    Issue.record("timed out")
                    #endif
                }
            }()
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
