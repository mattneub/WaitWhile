import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct WaitWhileMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        let expr: ExprSyntax = """
        {
            enum WaitError: Error {
                case success
                case timeout
            }
            try? await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    #if canImport(Testing)
                        // Issue.record("timed out")
                    #endif
                    throw WaitError.timeout
                }
                group.addTask {
                    while \(raw: argument.description) {
                        await Task.yield()
                        try Task.checkCancellation()
                    }
                    throw WaitError.success
                }
                for try await _ in group {}
            }
        }()
        """
        return expr
    }
}

@main
struct WaitWhilePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WaitWhileMacro.self,
    ]
}
