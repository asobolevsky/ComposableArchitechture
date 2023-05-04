//
//  Functions.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation
import CasePaths

public typealias Reducer<Value, Action, Environment> = (inout Value, Action, Environment) -> [Effect<Action>]

public func combine<Value, Action, Environment>(
    _ reducers: Reducer<Value, Action, Environment>...
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        return reducers.flatMap { $0(&value, action, environment) }
    }
}

public func pullback<
    LocalValue, GlobalValue,
    LocalAction, GlobalAction,
    LocalEnvironment, GlobalEnvironment
>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: CasePath<GlobalAction, LocalAction>,
    environment: @escaping (GlobalEnvironment) -> LocalEnvironment
) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment> {
    return { globalValue, globalAction, globalEnvironment in
        guard let localAction = action.extract(from: globalAction) else { return [] }
        let localEffects = reducer(&globalValue[keyPath: value], localAction, environment(globalEnvironment))
        return localEffects.map { localEffect in
            localEffect
                .map(action.embed)
                .eraseToEffect()
        }
    }
}

public func logging<Value, Action, Environment>(
    _ reducer: @escaping Reducer<Value, Action, Environment>
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        let effects = reducer(&value, action, environment)
        let newValue = value

        return [
            .fireAndForget {
                print("Action: \(action)")
                print("Value:")
                dump(newValue)
                print("---")
            }
        ] + effects
    }
}
