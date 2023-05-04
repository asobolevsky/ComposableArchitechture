//
//  Assertions.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation
import Combine
import ComposableArchitechture
import XCTest

public func assert<Value: Equatable, Action: Equatable, Environment>(
    initialValue: Value,
    reducer: Reducer<Value, Action, Environment>,
    environment: Environment,
    steps: [Step<Value, Action>],
    file: StaticString = #file,
    line: UInt = #line
) {
    var state = initialValue
    var effects: [Effect<Action>] = []
    var cancellables: Set<AnyCancellable> = []

    steps.forEach { step in
        var expected = state

        switch step.type {
        case .send:
            if !effects.isEmpty {
                XCTFail("Action sent before handling \(effects.count) effect(s)", file: step.file, line: step.line)
            }
            effects.append(contentsOf: reducer(&state, step.action, environment))

        case .receive:
            guard !effects.isEmpty else {
                XCTFail("No pending effects to receive from", file: step.file, line: step.line)
                return
            }

            let effect = effects.removeFirst()
            var action: Action!
            let receivedCompletion = XCTestExpectation(description: "receivedCompletion")

            effect.sink(
                receiveCompletion: { _ in
                    receivedCompletion.fulfill()
                },
                receiveValue: {
                    action = $0
                }
            )
            .store(in: &cancellables)

            let result = XCTWaiter.wait(for: [receivedCompletion], timeout: 1)
            if result != .completed {
                XCTFail("Failed to wait for receivedCompletion expectation", file: step.file, line: step.line)
            }
            XCTAssertEqual(action, step.action, file: step.file, line: step.line)
            effects.append(contentsOf: reducer(&state, step.action, environment))
        }

        step.update(&expected)
        XCTAssertEqual(state, expected, file: step.file, line: step.line)
    }
    if !effects.isEmpty {
        XCTFail("Assertion failed to handle \(effects.count) effect(s)", file: file, line: line)
    }
}
