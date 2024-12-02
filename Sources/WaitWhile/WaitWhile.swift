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
/// If we pause for too long, we hit a timeout limit and we move on, reporting a failure.
/// The default timeout is 5 seconds, but you can append a `timeout:` argument to set a different
/// amount (in nanoseconds):
///
///     await #while(myViewController.presentedViewController != nil, timeout: 1_000_000_000)
///
@freestanding(expression)
public macro `while`(
    _ value: Bool,
    timeout nanoseconds: Int = 5_000_000_000
) = #externalMacro(module: "WaitWhileMacros", type: "WaitWhileMacro")
