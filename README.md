# WaitWhile Macro

## What it does

This is a simple Swift Macro that grows out of a common pattern I find myself using a lot, now that I've adopted Swift Testing.

Let's say your unit test calls some app code that does something that takes some time, like, for example, this button action code that tells a processor to dismiss a view controller:

````swift
    /// Done button action.
    @IBAction func doDone(_ sender: Any) {
        Task {
            await processor?.receive(.dismissPurchase)
        }
    }
````

To test it, we mock the processor, call `doDone`, and look to see that the mock processor received the `.dismissPurchase` message. Fine. But there's a problem: if we simply write the test this way, it fails:

````swift
    @Test("doDone sends dismissPurchase")
    func doDone() async {
        subject.processor = mockProcessor
        subject.doDone(self)
        #expect(mockProcessor.messagesReceived.contains(.dismissPurchase))
    }
````

The reason for the failure is the `Task` call in the `doDone` routine. This causes a slight delay. We need somehow to _wait_ until the `.dismissPurchase` message is sent.

Now, what I was doing to solve this problem was to look repeatedly at the state of the mock processor in a `while` loop, calling `Task.yield()`, like this:

````swift
    @Test("doDone sends dismissPurchase")
    func doDone() async {
        subject.processor = mockProcessor
        subject.doDone(self)
        while mockProcessor.messagesReceived.isEmpty {
            await Task.yield()
        }
        #expect(mockProcessor.messagesReceived.contains(.dismissPurchase))
    }
````

That works great. But I was doing that _a lot_. So I wanted to embody that pattern as a macro, analogous from the caller's point of view to Swift Testing's `#expect`. With my macro, that same code is written like this:

````swift
    @Test("doDone sends dismissPurchase")
    func doDone() async {
        subject.processor = mockProcessor
        subject.doDone(self)
        await #while(mockProcessor.messagesReceived.isEmpty)
        #expect(mockProcessor.messagesReceived.contains(.dismissPurchase))
    }
````

That's all there is to it! It's a very simple macro, very simply written; I didn't do any of the clever stuff that Apple does with `#expect` behind the scenes.

## Timeout

The way I originally wrote this macro, if you made a `while` loop whose condition was _always_ true, the test wouldn’t fail or even finish — it would just hang. So I added a default timeout of 5 seconds. This makes the macro a bit more complicated, but that doesn’t matter, really, because you’re not supposed to worry about what a macro does behind the scenes (though of course you can see it if you really want to).

If the timeout is reached before the condition ceases to be true, the test will record a failure, and will resume running after the line containing the macro. Thus, the test will complete but will fail, which seems like just the behavior we want.

Moreover, you can change the timeout (which you might do, say, if the default is insufficiently long). Add a second parameter, `timeout`, whose value is a literal in nanoseconds:

```swift
        await #while(mockProcessor.messagesReceived.isEmpty, timeout: 7_000_000_000)
```



