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
    func testMacro() throws {
        #if canImport(WaitWhileMacros)
        assertMacroExpansion(
            """
            #while(1 == 1)
            """,
            expandedSource: """
            {
                enum WaitError: Error {
                    case success
                    case timeout
                }
                try? await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        #if canImport(Testing)
                            Issue.record("timed out")
                        #endif
                        throw WaitError.timeout
                    }
                    group.addTask {
                        while 1 == 1 {
                            await Task.yield()
                            try Task.checkCancellation()
                        }
                        throw WaitError.success
                    }
                    for try await _ in group {
                    }
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
