//
//  Store.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation
import Combine

public final class Store<Value, Action>: ObservableObject {
    @Published public private(set) var value: Value
    private let environment: Any
    private let reducer: Reducer<Value, Action, Any>
    private var effectCancellables: Set<AnyCancellable> = []
    private var viewCancellable: AnyCancellable?

    public init<Environment>(
        initialValue: Value,
        environment: Environment,
        reducer: @escaping Reducer<Value, Action, Environment>
    ) {
        self.value = initialValue
        self.environment = environment
        self.reducer = { value, action, environment in reducer(&value, action, environment as! Environment) }
    }

    public func send(_ action: Action) {
        let effects = reducer(&value, action, environment)
        effects.forEach { effect in
            var effectCancellable: AnyCancellable?
            var didComplete = false
            effectCancellable = effect.sink(
                receiveCompletion: { [weak self, weak effectCancellable] _ in
                    didComplete = true
                    if let effectCancellable {
                        self?.effectCancellables.remove(effectCancellable)
                    }
                },
                receiveValue: { [weak self] in self?.send($0) }
            )
            if !didComplete, let effectCancellable {
                effectCancellables.insert(effectCancellable)
            }
        }
    }

    public func view<LocalValue: Equatable, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(value),
            environment: environment,
            reducer: { localValue, localAction, localEnvironmenr in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            }
        )
        localStore.viewCancellable = $value
            .map(toLocalValue)
            .removeDuplicates()
            .sink { [weak localStore] newValue in
                localStore?.value = newValue
            }
        return localStore
    }
}
