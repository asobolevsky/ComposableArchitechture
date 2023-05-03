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
        _ update: @escaping (inout Value) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.type = type
        self.action = action
        self.update = update
        self.file = file
        self.line = line
    }

    public enum StepType {
        case send
        case receive
    }
}
