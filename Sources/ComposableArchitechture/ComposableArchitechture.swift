import Combine
import SwiftUI

// MARK: - Types

public typealias Effect<Action> = () -> Action?

public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

// MARK: - Functions

public func with<A, B>(_ a: A, _ f: (A) throws -> B) rethrows -> B {
    return try f(a)
}

public func compose<A, B, C>(
    _ f: @escaping (B) -> C,
    _ g: @escaping (A) -> B
) -> (A) -> C {
    return { a in
        f(g(a))
    }
}

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    return { value, action in
        return reducers.flatMap { $0(&value, action) }
    }
}

public func pullback<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return [] }
        let localEffects = reducer(&globalValue[keyPath: value], localAction)
        return localEffects.map { localEffect in
            return { () -> GlobalAction? in
                guard let localAction = localEffect() else { return nil }
                var globalAction = globalAction
                globalAction[keyPath: action] = localAction
                return globalAction
            }
        }
    }
}

// MARK: - Store

public final class Store<Value, Action>: ObservableObject {
    @Published public private(set) var value: Value
    private let reducer: Reducer<Value, Action>
    private var cancellable: AnyCancellable?

    public init(initialValue: Value, reducer: @escaping Reducer<Value, Action>) {
        self.value = initialValue
        self.reducer = reducer
    }

    public func send(_ action: Action) {
        let effects = reducer(&value, action)
        effects.forEach {
            if let action = $0() {
                send(action)
            }
        }
    }

    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(value),
            reducer: { localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            }
        )
        localStore.cancellable = $value.sink { [weak localStore] newValue in
            localStore?.value = toLocalValue(newValue)
        }
        return localStore
    }
}

public struct ComposableArchitechture {
    public private(set) var text = "Hello, World!"

    public init() { }
}
