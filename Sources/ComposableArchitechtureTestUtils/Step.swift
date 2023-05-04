//
//  Step.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation

public struct Step<Value: Equatable, Action> {
    public let type: StepType
    public let action: Action
    public let update: (inout Value) -> Void
    public let file: StaticString
    public let line: UInt

    public init(
        _ type: StepType,
        _ action: Action,
        file: StaticString = #file,
        line: UInt = #line,
        _ update: @escaping (inout Value) -> Void = { _ in }
    ) {
        self.type = type
        self.action = action
        self.file = file
        self.line = line
        self.update = update
    }

    public enum StepType {
        case send
        case receive
    }
}
