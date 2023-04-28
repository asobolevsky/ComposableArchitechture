//
//  Effects.swift
//  
//
//  Created by Aleksei Sobolevskii on 2023-04-28.
//

import Foundation

// MARK: - Standalone

public func dataTask(with url: URL) -> Effect<(Data?, URLResponse?, Error?)> {
    Effect { callback in
        URLSession.shared.dataTask(with: url) { data, response, error in
            callback((data, response, error))
        }
        .resume()
    }
}

// MARK: - Extensions

extension Effect {
    public func receive(on queue: DispatchQueue) -> Effect {
        Effect { callback in
            run { a in
                queue.async { callback(a) }
            }
        }
    }
}

extension Effect where A == (Data?, URLResponse?, Error?) {
    public func decode<M: Decodable>(as type: M.Type) -> Effect<M?> {
        map { data, _, _ in
            data.flatMap { try? JSONDecoder().decode(type, from: $0) }
        }
    }
}
