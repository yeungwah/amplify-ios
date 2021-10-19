//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

// LazyModel? - can be nil
// if LazyModel is not nil, then we have the model and hasn't loaded it yet.
public class LazyModel<ModelType: Model>: Codable, LazyModelMarker {
    public var id: String? {
        provider.id
    }

    enum LoadedState {
        case notLoaded
        case loaded(ModelType?)
    }

    var loadedState: LoadedState

    public let provider: AnyLazyModelProvider<ModelType>

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
        let provider = LoadedModelProvider(element: instance).eraseToAnyLazyModelProvider()
        self.init(provider: provider)
    }

    required convenience public init(from decoder: Decoder) throws {
        for modelDecoder in LazyModelDecoderRegistry.decoders.get() {
            if modelDecoder.shouldDecode(modelType: ModelType.self, decoder: decoder) {
                let provider = try modelDecoder.makeProvider(modelType: ModelType.self, decoder: decoder)
                self.init(provider: provider)
                return
            }
        }

        let container = try decoder.singleValueContainer()
        let model = try container.decode(ModelType.self)
        self.init(model)
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
