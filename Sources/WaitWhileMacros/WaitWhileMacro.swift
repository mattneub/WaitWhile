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
        var timeout = "5_000_000_000"
        if node.arguments.count == 2 {
            if let userTimeout = node.arguments
                .children(viewMode: .all).last?
                .as(LabeledExprSyntax.self)?.expression
                .as(IntegerLiteralExprSyntax.self)?.description {
                timeout = userTimeout
            }
        }
        let expr: ExprSyntax = """
        { () -> Void in
            var timeoutTask: Task<(), any Error>? = nil
            let mainTask = Task {
                while \(raw: argument.description) {
                    await Task.yield()
                    try Task.checkCancellation()
                }
                timeoutTask?.cancel()
            }
            timeoutTask = Task.detached {
                try await Task.sleep(nanoseconds: \(raw: timeout))
                mainTask.cancel()
                #if canImport(Testing)
                Issue.record("timed out")
                #endif
            }
            _ = await mainTask.result
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
