//
//  Store.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Combine
import Foundation

public final class Store<Value, Action> {
    @Published fileprivate var value: Value
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

    public func scope<LocalValue, LocalAction>(
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
            .sink { [weak localStore] newValue in
                localStore?.value = newValue
            }
        return localStore
    }
}

// MARK: - ViewStore

public final class ViewStore<Value>: ObservableObject {
    @Published public fileprivate(set) var value: Value
    fileprivate var cancellable: Cancellable?

    public init(initialValue value: Value) {
        self.value = value
    }
}

public extension Store where Value: Equatable {
    var view: ViewStore<Value> {
        view(removeDuplciates: ==)
    }
}

public extension Store {
    func view(removeDuplciates predicate: @escaping (Value, Value) -> Bool) -> ViewStore<Value> {
        let viewStore = ViewStore(initialValue: value)

        viewStore.cancellable = $value
            .removeDuplicates(by: predicate)
            .sink(receiveValue: { [weak viewStore] value in
                viewStore?.value = value
                self
            })

        return viewStore
    }
}
