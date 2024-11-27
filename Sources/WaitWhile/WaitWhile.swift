/// A macro that pauses in an async context (expected to be a test method)
/// so long as a given Bool is true.
///
/// For example:
///
///     await #while(myViewController.presentedViewController != nil)
///
/// produces the equivalent of:
///
///     while myViewController.presentedViewController != nil {
///         await Task.yield()
///     }
///
/// Thus we have effectively waited for a presented view controller to be dismissed.
///
@freestanding(expression)
public macro `while`(_ value: Bool) = #externalMacro(module: "WaitWhileMacros", type: "WaitWhileMacro")
