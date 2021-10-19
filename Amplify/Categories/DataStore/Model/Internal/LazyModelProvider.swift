//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Empty protocol used as a marker to detect when the type is a `LazyModel`
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol LazyModelMarker {
    var id: Model.Identifier? { get }
}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol LazyModelProvider {
    associatedtype Element: Model

    var id: Model.Identifier? { get }

    func load() -> Result<Element?, CoreError>

    func load(completion: @escaping (Result<Element?, CoreError>) -> Void)
}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public struct AnyLazyModelProvider<Element: Model>: LazyModelProvider {
    public let id: String?
    private let loadClosure: () -> Result<Element?, CoreError>
    private let loadWithCompletionClosure: (@escaping (Result<Element?, CoreError>) -> Void) -> Void

    public init<Provider: LazyModelProvider>(provider: Provider) where Provider.Element == Self.Element {
        self.id = provider.id
        self.loadClosure = provider.load
        self.loadWithCompletionClosure = provider.load(completion:)
    }

    public func load() -> Result<Element?, CoreError> {
        loadClosure()
    }

    public func load(completion: @escaping (Result<Element?, CoreError>) -> Void) {
        loadWithCompletionClosure(completion)
    }

}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public extension LazyModelProvider {
    func eraseToAnyLazyModelProvider() -> AnyLazyModelProvider<Element> {
        AnyLazyModelProvider(provider: self)
    }
}
