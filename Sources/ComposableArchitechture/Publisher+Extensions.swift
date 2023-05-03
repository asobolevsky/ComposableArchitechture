//
//  File.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation
import Combine

public extension Publisher where Failure == Never {
    func eraseToEffect() -> Effect<Output> {
        Effect(publisher: eraseToAnyPublisher())
    }
}

public extension Publisher where Output == Never, Failure == Never {
    func fireAndForget<A>() -> Effect<A> {
        map(absurd).eraseToEffect()
    }
}
