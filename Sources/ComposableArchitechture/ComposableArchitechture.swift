import Combine
import SwiftUI

// MARK: - Types

public typealias StateReducer<State, Action> = (inout State, Action) -> Void

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
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}

public func pullback<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}

// MARK: - Store

public final class Store<State, Action>: ObservableObject {
    @Published public private(set) var state: State
    private let reducer: StateReducer<State, Action>
    private var cancellable: AnyCancellable?

    public init(initialState: State, reducer: @escaping StateReducer<State, Action>) {
        self.state = initialState
        self.reducer = reducer
    }

    public func send(_ action: Action) {
        reducer(&state, action)
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
