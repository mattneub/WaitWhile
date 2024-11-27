import WaitWhile

@MainActor
struct PseudoTest {
    let subject = PseudoTestee()
    func doPseudoTest() async {
        print("start")
        Task {
            try await subject.doSomethingTimeConsuming()
        }
        await #while(subject.value == 1)
        print("done")
    }
}

@MainActor
class PseudoTestee {
    var value = 1

    func doSomethingTimeConsuming() async throws {
        if #available(macOS 13.0, iOS 16.0, *) {
            try await Task.sleep(for: .seconds(1))
        }
        value = 2
    }
}

let test = PseudoTest()
await test.doPseudoTest()

