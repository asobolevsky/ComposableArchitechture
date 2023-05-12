//
//  Function.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation
import CasePaths

public struct Reducer<Value, Action, Environment> {
    fileprivate let reducer: (inout Value, Action, Environment) -> [Effect<Action>]

    public init(_ reducer: @escaping (inout Value, Action, Environment) -> [Effect<Action>]) {
        self.reducer = reducer
    }
}

extension Reducer {
    public func callAsFunction(_ value: inout Value, _ action: Action, _ environment: Environment) ->  [Effect<Action>] {
        self.reducer(&value, action, environment)
    }
}

extension Reducer {
    public static func combine(_ reducers: Reducer...) -> Reducer {
        return .init { value, action, environment in
            return reducers.flatMap { $0(&value, action, environment) }
        }
    }

    public func pullback<GlobalValue, GlobalAction, GlobalEnvironment>(
        value: WritableKeyPath<GlobalValue, Value>,
        action: CasePath<GlobalAction, Action>,
        environment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment> {
        return .init { globalValue, globalAction, globalEnvironment in
            guard let localAction = action.extract(from: globalAction) else { return [] }
            let localEffects = self(&globalValue[keyPath: value], localAction, environment(globalEnvironment))
            return localEffects.map { localEffect in
                localEffect
                    .map(action.embed)
                    .eraseToEffect()
            }
        }
    }

    public func logging(
        printer: @escaping (Environment) -> (String) -> Void = { _ in { print($0) } }
    ) -> Reducer {
        return .init { value, action, environment in
            let effects = self(&value, action, environment)
            let newValue = value
            let print = printer(environment)

            return [
                .fireAndForget {
                    print("Action: \(action)")
                    print("Value:")
                    var dumpedNewValue = ""
                    dump(newValue, to: &dumpedNewValue)
                    print(dumpedNewValue)
                    print("---")
                }
            ] + effects
        }
    }
}
