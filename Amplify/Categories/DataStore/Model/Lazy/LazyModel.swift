//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

public protocol LazyModelMarker {
    //var id: Model.Identifier { get }
}

public protocol LazyModelProvider {
    associatedtype Element: Model

    func load() -> Result<Element?, CoreError>

    func load(completion: @escaping (Result<Element?, CoreError>) -> Void)
}

public struct AnyLazyModelProvider<Element: Model>: LazyModelProvider {

    private let loadClosure: () -> Result<Element?, CoreError>
    private let loadWithCompletionClosure: (@escaping (Result<Element?, CoreError>) -> Void) -> Void

    public init<Provider: LazyModelProvider>(provider: Provider) where Provider.Element == Self.Element {
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

public extension LazyModelProvider {
    func eraseToAnyLazyModelProvider() -> AnyLazyModelProvider<Element> {
        AnyLazyModelProvider(provider: self)
    }
}

public struct ModelProvider<Element: Model>: LazyModelProvider {
    let element: Element?

    public init(element: Element?) {
        self.element = element
    }

    public func load() -> Result<Element?, CoreError> {
        .success(element)
    }

    public func load(completion: @escaping (Result<Element?, CoreError>) -> Void) {
        completion(.success(element))
    }
}
public class LazyModel<ModelType: Model>: Codable, LazyModelMarker {
    //public let id: Model.Identifier

    enum LoadedState {
        case notLoaded
        case loaded(ModelType?)
    }

    var loadedState: LoadedState

    let provider: AnyLazyModelProvider<ModelType>

    public var instance: ModelType? {
        get {
            switch loadedState {
            case .loaded(let instance):
                return instance
            case .notLoaded:
                let result = provider.load()
                switch result {
                case .success(let instance):
                    loadedState = .loaded(instance)
                    return instance
                case .failure(let error):
                    Amplify.log.error(error: error)
                    return nil
                }
            }
        }

        set {
            loadedState = .loaded(newValue!)
        }
    }

    // MARK: - Initializers

    public init(provider: AnyLazyModelProvider<ModelType>) {
        self.provider = provider
        self.loadedState = .notLoaded
    }

    public convenience init(_ instance: ModelType?) {
        let provider = ModelProvider(element: instance).eraseToAnyLazyModelProvider()
        self.init(provider: provider)
    }

    required convenience public init(from decoder: Decoder) throws {

        for modelDecoder in LazyModelDecoderRegistry.decoders.get() {
            if modelDecoder.shouldDecode(modelType: ModelType.self, decoder: decoder) {
                let provider = try modelDecoder.makeProvider(modelType: ModelType.self, decoder: decoder)
                self.init(provider: provider)
            }
        }

        let json = try JSONValue(from: decoder)
        print(json)

        // TODO:  move this to the decoder, then
        switch json {
        case .object(let associationData):
            if case let .string(id) = associationData["id"] {
                // self.init(id: id)

            }
        default:
            break
        }

        self.init(nil)
    }

    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded:
            throw DataStoreError.unknown("Failed to encode.",
                                         "See underlying DataStoreError for more details.", nil)
        case .loaded(let instance):
            try instance.encode(to: encoder)
        }
    }
}
