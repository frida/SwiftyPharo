import XCTest

@testable import SwiftyPharo

final class PharoInterruptTests: XCTestCase {
    func testAnEndlessLoopIsInterruptedAtOnce() async throws {
        try await expectInterruptedAtOnce("[ true ] whileTrue")
    }

    func testAWaitOnADelayIsInterruptedAtOnce() async throws {
        try await expectInterruptedAtOnce("(Delay forSeconds: 60) wait")
    }

    func testADeepRecursionIsInterruptedOnceTheCollectorLetsGo() async throws {
        let runtime = try await runtime()
        let before = try await census(of: runtime)
        for _ in 0..<5 {
            let collecting = try await collectorMilliseconds(of: runtime)
            let outcome = try await interrupt(
                "| descend | descend := [ :depth | descend value: depth + 1 ]. descend value: 0",
                after: .random(in: 20_000_000...200_000_000),
                in: runtime)
            let collected = Double(try await collectorMilliseconds(of: runtime) - collecting) / 1000
            XCTAssertTrue(outcome.result.isInterruption, "\(outcome.result)")
            XCTAssertLessThan(outcome.latency, collected + Self.promptly)
            try await expectUnwound(in: runtime)
            print("deep recursion: interrupt took \(outcome.latency) s, the collector \(collected) s of the cycle")
        }
        let after = try await census(of: runtime)
        XCTAssertEqual(after, before)
    }

    func testALoopInsideEnsureIsInterruptedAtOnce() async throws {
        try await expectInterruptedAtOnce("[ [ true ] whileTrue ] ensure: [ Smalltalk at: #SwpInnerUnwound put: true ]")
        let inner = try await runtime().evaluate("Smalltalk at: #SwpInnerUnwound")
        XCTAssertEqual(inner.printString, "true")
        try await runtime().release(inner)
    }

    func testANormalEvaluationAnswersOrIsInterrupted() async throws {
        let runtime = try await runtime()
        let before = try await census(of: runtime)
        var answered = 0
        for _ in 0..<20 {
            let outcome = try await interrupt(
                "(1 to: 200000) inject: 0 into: [ :sum :each | sum + each ]",
                after: .random(in: 0...20_000_000),
                in: runtime)
            switch outcome.result {
            case .success(let sum):
                XCTAssertEqual(sum.printString, "20000100000")
                try await runtime.release(sum)
                answered += 1
            case .failure(let error):
                XCTAssertTrue(error.isInterruption, "\(error)")
                XCTAssertLessThan(outcome.latency, Self.promptly)
            }
            try await expectUnwound(in: runtime)
        }
        let after = try await census(of: runtime)
        XCTAssertEqual(after, before)
        print("normal evaluation: \(answered) of 20 answered before their interrupt")
    }

    func testARequestQueuedBehindAnInterruptedOneStartsAtOnce() async throws {
        let runtime = try await runtime()
        let ahead = Task { try await runtime.evaluate("[ true ] whileTrue") }
        try await Task.sleep(nanoseconds: 50_000_000)
        let behind = Task { () -> (PharoObject, UInt64) in
            let answer = try await runtime.evaluate("3 + 4")
            return (answer, DispatchTime.now().uptimeNanoseconds)
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        let cancelledAt = DispatchTime.now().uptimeNanoseconds
        ahead.cancel()
        let (answer, answeredAt) = try await behind.value
        XCTAssertEqual(answer.printString, "7")
        XCTAssertGreaterThan(answeredAt, cancelledAt)
        XCTAssertLessThan(Self.seconds(answeredAt - cancelledAt), Self.promptly)
        let aheadResult = await ahead.result
        XCTAssertTrue(aheadResult.isInterruption)
        try await runtime.release(answer)
    }

    func testInterruptingAQueuedRequestRemovesItUnrun() async throws {
        let runtime = try await runtime()
        try await runtime.release(try await runtime.evaluate("Smalltalk at: #SwpQueuedRan put: false"))
        let ahead = Task { try await runtime.evaluate("[ true ] whileTrue") }
        try await Task.sleep(nanoseconds: 50_000_000)
        let behind = Task { try await runtime.evaluate("Smalltalk at: #SwpQueuedRan put: true") }
        try await Task.sleep(nanoseconds: 50_000_000)
        let cancelledAt = DispatchTime.now().uptimeNanoseconds
        behind.cancel()
        let behindResult = await behind.result
        XCTAssertTrue(behindResult.isInterruption)
        XCTAssertLessThan(Self.seconds(DispatchTime.now().uptimeNanoseconds - cancelledAt), Self.promptly)
        ahead.cancel()
        let aheadResult = await ahead.result
        XCTAssertTrue(aheadResult.isInterruption)
        let ran = try await runtime.evaluate("Smalltalk at: #SwpQueuedRan")
        XCTAssertEqual(ran.printString, "false")
        try await runtime.release(ran)
    }

    func testAThousandInterruptsLeaveNothingBehind() async throws {
        let runtime = try await runtime()
        let before = try await census(of: runtime)
        let started = DispatchTime.now().uptimeNanoseconds
        var slowest = 0.0
        for _ in 0..<1000 {
            let outcome = try await interrupt("[ true ] whileTrue", after: .random(in: 0...2_000_000), in: runtime)
            XCTAssertTrue(outcome.result.isInterruption)
            slowest = max(slowest, outcome.latency)
            let answer = try await runtime.evaluate("1 + 1")
            XCTAssertEqual(answer.printString, "2")
            try await runtime.release(answer)
        }
        let after = try await census(of: runtime)
        XCTAssertEqual(after, before)
        print("1000 interrupt/evaluate cycles: \(Self.seconds(DispatchTime.now().uptimeNanoseconds - started)) s, slowest interrupt \(slowest) s")
    }

    func testCancellationRacingCompletionSettlesEachRequestOnce() async throws {
        let runtime = try await runtime()
        let before = try await census(of: runtime)
        var answered = 0
        for _ in 0..<1000 {
            let quick = Task { try await runtime.evaluate("3 + 4") }
            try await Task.sleep(nanoseconds: .random(in: 0...1_000_000))
            quick.cancel()
            switch await quick.result {
            case .success(let seven):
                XCTAssertEqual(seven.printString, "7")
                try await runtime.release(seven)
                answered += 1
            case .failure(let error):
                XCTAssertTrue(error.isInterruption, "\(error)")
            }
        }
        let after = try await census(of: runtime)
        XCTAssertEqual(after, before)
        print("cancellation racing completion: \(answered) of 1000 answered")
    }

    func testAnUnwindBlockThatNeverEndsIsAbandonedAfterItsGrace() async throws {
        let runtime = try await runtime()
        let before = try await census(of: runtime)
        let outcome = try await interrupt("[ 1 ] ensure: [ [ true ] whileTrue ]", after: 50_000_000, in: runtime)
        XCTAssertTrue(outcome.result.isInterruption)
        XCTAssertGreaterThan(outcome.latency, 1.9)
        XCTAssertLessThan(outcome.latency, 2.5)
        let answer = try await runtime.evaluate("3 + 4")
        XCTAssertEqual(answer.printString, "7")
        try await runtime.release(answer)
        let after = try await census(of: runtime)
        XCTAssertEqual(after, before)
    }

    func testAHandlerForEveryExceptionDoesNotHoldTheInterruptBack() async throws {
        try await expectInterruptedAtOnce("[ [ [ true ] whileTrue ] on: Exception do: [ :failure | failure return: nil ] ] repeat")
    }

    func testAMutexAnInterruptedRequestHeldIsReleased() async throws {
        let runtime = try await runtime()
        try await runtime.release(try await runtime.evaluate("Smalltalk at: #SwpHeldMutex put: Mutex new"))
        try await expectInterruptedAtOnce("(Smalltalk at: #SwpHeldMutex) critical: [ [ true ] whileTrue ]")
        let entered = try await runtime.evaluate("(Smalltalk at: #SwpHeldMutex) critical: [ 42 ]")
        XCTAssertEqual(entered.printString, "42")
        try await runtime.release(entered)
    }

    func testAProcessAnInterruptedRequestForkedOutlivesIt() async throws {
        let runtime = try await runtime()
        let outcome = try await interrupt(
            "[ (Delay forSeconds: 60) wait ] forkNamed: 'SwpChild'. [ true ] whileTrue", after: 50_000_000, in: runtime)
        XCTAssertTrue(outcome.result.isInterruption)
        let children = try await runtime.evaluate(
            "(Process allSubInstances select: [ :each | each name = 'SwpChild' and: [ each isTerminated not ] ]) do: [ :each | each terminate ]; size")
        XCTAssertEqual(children.printString, "1")
        try await runtime.release(children)
    }

    func testACallOnTheInterpreterThreadIsInterruptedOnlyOnceItReturns() async throws {
        let runtime = try await runtime()
        let outcome = try await interrupt(
            """
            TFSameThreadRunner uniqueInstance
                invokeFunction: (TFExternalFunction
                    fromAddress: (ExternalAddress loadSymbol: 'usleep' module: nil)
                    definition: (TFFunctionDefinition parameterTypes: { TFBasicType uint32 } returnType: TFBasicType sint32))
                withArguments: #(500000).
            [ true ] whileTrue
            """,
            after: 100_000_000,
            in: runtime)
        XCTAssertTrue(outcome.result.isInterruption)
        XCTAssertGreaterThan(outcome.latency, 0.3)
        print("interrupting a 500 ms call on the interpreter thread after 100 ms took \(outcome.latency) s")
    }

    func testAnErrorInAnUnwindBlockCutsOnlyThatBlockShort() async throws {
        let runtime = try await runtime()
        let before = try await census(of: runtime)
        try await runtime.release(try await runtime.evaluate("Smalltalk at: #SwpPastTheError put: false"))
        let outcome = try await interrupt(
            "[ [ true ] whileTrue ] ensure: [ 1 / 0. Smalltalk at: #SwpPastTheError put: true ]", after: 50_000_000, in: runtime)
        XCTAssertTrue(outcome.result.isInterruption, "\(outcome.result)")
        XCTAssertLessThan(outcome.latency, Self.promptly)
        try await expectUnwound(in: runtime)
        let past = try await runtime.evaluate("Smalltalk at: #SwpPastTheError")
        XCTAssertEqual(past.printString, "false")
        try await runtime.release(past)
        let after = try await census(of: runtime)
        XCTAssertEqual(after, before)
    }

    private static let promptly = 0.1

    private func expectInterruptedAtOnce(_ source: String) async throws {
        let runtime = try await runtime()
        let before = try await census(of: runtime)
        var slowest = 0.0
        for _ in 0..<5 {
            let outcome = try await interrupt(source, after: .random(in: 20_000_000...200_000_000), in: runtime)
            XCTAssertTrue(outcome.result.isInterruption, "\(outcome.result)")
            XCTAssertLessThan(outcome.latency, Self.promptly)
            slowest = max(slowest, outcome.latency)
            try await expectUnwound(in: runtime)
        }
        let after = try await census(of: runtime)
        XCTAssertEqual(after, before)
        print("\(source): slowest of 5 interrupts took \(slowest) s")
    }

    private func interrupt(_ source: String, after delay: UInt64, in runtime: PharoRuntime) async throws -> Outcome {
        try await runtime.release(try await runtime.evaluate("Smalltalk at: #SwpUnwound put: false"))
        let evaluation = Task { try await runtime.evaluate("[ \(source) ] ensure: [ Smalltalk at: #SwpUnwound put: true ]") }
        try await Task.sleep(nanoseconds: delay)
        let cancelledAt = DispatchTime.now().uptimeNanoseconds
        evaluation.cancel()
        let result = await evaluation.result
        return Outcome(result: result, latency: Self.seconds(DispatchTime.now().uptimeNanoseconds - cancelledAt))
    }

    private func expectUnwound(in runtime: PharoRuntime) async throws {
        let unwound = try await runtime.evaluate("Smalltalk at: #SwpUnwound")
        XCTAssertEqual(unwound.printString, "true")
        try await runtime.release(unwound)
    }

    private func collectorMilliseconds(of runtime: PharoRuntime) async throws -> Int {
        let total = try await runtime.evaluate("Smalltalk vm totalFullGCTime + Smalltalk vm totalIncrementalGCTime")
        try await runtime.release(total)
        return Int(total.printString)!
    }

    private func census(of runtime: PharoRuntime) async throws -> [Int] {
        let counted = try await runtime.evaluate(
            """
            Smalltalk garbageCollect.
            { (Process allSubInstances reject: [ :each | each isTerminated ]) size.
              (SwpBridge current session instVarNamed: #objectsByHandle) size } printString
            """)
        try await runtime.release(counted)
        return counted.printString.split(whereSeparator: { !$0.isNumber }).map { Int($0)! }
    }

    private func runtime() async throws -> PharoRuntime {
        let image = try XCTUnwrap(ProcessInfo.processInfo.environment["SWIFTY_PHARO_IMAGE"], "set SWIFTY_PHARO_IMAGE to run this")
        let runtime = PharoRuntime.shared
        let booting = runtime.state == .starting
        runtime.boot(image: URL(fileURLWithPath: image))
        try await runtime.runningState()
        if booting {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        return runtime
    }

    private static func seconds(_ nanoseconds: UInt64) -> Double {
        Double(nanoseconds) / 1_000_000_000
    }

    private struct Outcome {
        let result: Result<PharoObject, any Error>
        let latency: Double
    }
}

extension Error {
    fileprivate var isInterruption: Bool {
        if case .interrupted = self as? PharoRequestError { return true }
        return false
    }
}

extension Result {
    fileprivate var isInterruption: Bool {
        if case .failure(let error) = self { return error.isInterruption }
        return false
    }
}
