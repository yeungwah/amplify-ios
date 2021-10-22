//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct LoadedModelProvider<Element: Model>: LazyModelProvider {
    public let id: Model.Identifier?
    let element: Element?

    public init(element: Element?) {
        self.element = element
        self.id = element?.id
    }

    public func load() -> Result<Element?, CoreError> {
        .success(element)
    }

    public func load(completion: @escaping (Result<Element?, CoreError>) -> Void) {
        completion(.success(element))
    }
}
