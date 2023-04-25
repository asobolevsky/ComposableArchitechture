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

public final class Store<State, Action>: ObservableObject {
    @Published public private(set) var state: State
    private let reducer: Reducer<State, Action>
    private var cancellable: AnyCancellable?

    public init(initialState: State, reducer: @escaping Reducer<State, Action>) {
        self.state = initialState
        self.reducer = reducer
    }

    public func send(_ action: Action) {
        let effects = reducer(&state, action)
        effects.forEach {
            if let action = $0() {
                send(action)
            }
        }
    }

    public func view<LocalState, LocalAction>(
        state toLocalState: @escaping (State) -> LocalState,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalState, LocalAction> {
        let localStore = Store<LocalState, LocalAction>(
            initialState: toLocalState(state),
            reducer: { localState, localAction in
                self.send(toGlobalAction(localAction))
                localState = toLocalState(self.state)
                return []
            }
        )
        localStore.cancellable = $state.sink { [weak localStore] newValue in
            localStore?.state = toLocalState(newValue)
        }
        return localStore
    }
}

public struct ComposableArchitechture {
    public private(set) var text = "Hello, World!"

    public init() { }
}
