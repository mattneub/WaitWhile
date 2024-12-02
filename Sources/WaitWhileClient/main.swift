import WaitWhile
import Testing

/// You can't run this; it's just so we can peek at the macro expansions.
struct PseudoTest {
    func doPseudoTest1() async {
        await #while(1 == 1)
    }
    func doSpeudoTest2() async {
        await #while(1 == 1, timeout: 1_000_000_000)
    }
}

