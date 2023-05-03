//
//  Step.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation

struct Step<Value: Equatable, Action> {
    let type: StepType
    let action: Action
    let update: (inout Value) -> Void
    let file: StaticString
    let line: UInt

    init(
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

    enum StepType {
        case send
        case receive
    }
}
