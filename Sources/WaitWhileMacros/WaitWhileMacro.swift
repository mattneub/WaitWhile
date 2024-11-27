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
            while \(raw: argument.description) {
                await Task.yield()
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
