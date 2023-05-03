//
//  File.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-05-03.
//

import Foundation

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

public func absurd<A>(_ never: Never) -> A {}
