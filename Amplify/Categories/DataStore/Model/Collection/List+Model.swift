//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

public protocol LazyModelMarker {
    var id: String { get }
}

public protocol LazyModelProvider {
    associatedtype Instance: Model
    func fetch() -> Result<Instance, DataStoreError>
    func fetch(completion: @escaping (Result<Instance, DataStoreError>) -> Void)
}

public class LazyModel<ModelType: Model>: Codable, LazyModelMarker, LazyModelProvider {

    public let id: String
    var loadedState: LoadedState

    enum LoadedState {
        case notLoaded
        case loaded(ModelType)
    }
    
    init(id: String) {
        self.id = id
        self.loadedState = .notLoaded
    }
    
    init(_ instance: ModelType) {
        self.id = instance.id
        self.loadedState = .notLoaded
    }

    public var instance: ModelType? {
        get {
            switch loadedState {
            case .loaded(let instance):
                return instance
            case .notLoaded:
                let result = fetch()
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
            switch loadedState {
            case .loaded:
                Amplify.log.error("Error")
                return
            case .notLoaded:
                loadedState = .loaded(newValue!)
            }
        }
    }
    
    public func fetch() -> Result<ModelType, DataStoreError> {
        let semaphore = DispatchSemaphore(value: 0)
        var loadResult: Result<ModelType, DataStoreError> =
            .failure(.unknown("Failed to Query DataStore.", "See underlying DataStoreError for more details.", nil))
        
        fetch { result in
            defer {
                semaphore.signal()
            }
            switch result {
            case .success(let instance):
                loadResult = .success(instance)
            case .failure(let error):
                Amplify.DataStore.log.error(error: error)
                assert(false, error.localizedDescription)
                loadResult = .failure(error)
            }
        }
        semaphore.wait()
        return loadResult
    }
    
    public func fetch(completion: (Result<ModelType, DataStoreError>) -> Void) {
        switch loadedState {
        case .loaded(let instance):
            completion(.success(instance))
        case .notLoaded:
            Amplify.DataStore.query(ModelType.self, byId: id) {
                switch $0 {
                case .success(let instance):
                    self.instance = instance
                    completion(.success(instance!))
                case .failure(let error):
                    Amplify.DataStore.log.error(error: error)
                    completion(.failure(DataStoreError.unknown("Failed to Query DataStore.",
                                                               "See underlying DataStoreError for more details.",
                                                               error)))
                }
            }
        }
    }
    
    // Decoder gets called when the object is created
    required convenience public init(from decoder: Decoder) throws {
        // "post": //decoder information
        let json = try JSONValue(from: decoder)
        // json = { id: "", modelName: "Post4" }
        print("Decoding \(json)")
        switch json {
        case .object(let associationData):
            if case let .string(id) = associationData["id"] {
                self.init(id: id)
                return
            }
        default:
            break
        }
        
        throw DataStoreError.unknown("Failed to decode.",
                                     "See underlying DataStoreError for more details.", nil)
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

/// `List<ModelType>` is a custom `Collection` that is capable of loading records from a data source. This is especially
/// useful when dealing with Model associations that need to be lazy loaded. Lazy loading is performed when you access
/// the `Collection` methods by retrieving the data from the underlying data source and then stored into this object,
/// before returning the data to you. Consumers must be aware that multiple calls to the data source and then stored
/// into this object will happen simultaneously if the object is used from different threads, thus not thread safe.
/// Lazy loading is idempotent and will return the stored results on subsequent access.
public class List<ModelType: Model>: Collection, Codable, ExpressibleByArrayLiteral, ModelListMarker {
    public typealias Index = Int
    public typealias Element = ModelType

    /// Represents the data state of the `List`.
    enum LoadedState {
        case notLoaded
        case loaded([Element])
    }

    /// The current state of lazily loaded list
    var loadedState: LoadedState

    /// The provider for fulfilling list behaviors
    let listProvider: AnyModelListProvider<Element>

    /// The array of `Element` that backs the custom collection implementation.
    ///
    /// Attempting to access the list object will attempt to retrieve the elements in memory or retrieve it from the
    /// provider's data source. This is not thread safe as it can be performed from multiple threads, however the
    /// provider's call to `load` should be idempotent and should result in the final loaded state. An attempt to set
    /// this again will result in no-op and will not overwrite the existing loaded data.
    public internal(set) var elements: [Element] {
        get {
            switch loadedState {
            case .loaded(let elements):
                return elements
            case .notLoaded:
                let result = listProvider.load()
                switch result {
                case .success(let elements):
                    loadedState = .loaded(elements)
                    return elements
                case .failure(let error):
                    Amplify.log.error(error: error)
                    return []
                }
            }
        }
        set {
            switch loadedState {
            case .loaded:
                Amplify.log.error("""
                    There is an attempt to set an already loaded List. The existing data will not be overwritten
                    """)
                return
            case .notLoaded:
                loadedState = .loaded(newValue)
            }
        }
    }

    // MARK: - Initializers

    public init(listProvider: AnyModelListProvider<ModelType>) {
        self.listProvider = listProvider
        self.loadedState = .notLoaded
    }

    public convenience init(elements: [Element]) {
        let loadProvider = ArrayLiteralListProvider<ModelType>(elements: elements).eraseToAnyModelListProvider()
        self.init(listProvider: loadProvider)
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements: elements)
    }

    // MARK: - Collection conformance

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public var startIndex: Index {
        elements.startIndex
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public var endIndex: Index {
        elements.endIndex
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public func index(after index: Index) -> Index {
        elements.index(after: index)
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public subscript(position: Int) -> Element {
        elements[position]
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public __consuming func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public var count: Int {
        elements.count
    }

    // MARK: - Persistent Operations

    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    /// `limit` is currently not a supported API.
    @available(*, deprecated, message: "Not supported.")
    public func limit(_ limit: Int) -> Self {
        return self
    }

    // MARK: - Codable

    /// The decoding logic uses `ModelListDecoderRegistry` to find available decoders to decode to plugin specific
    /// implementations of a `ModelListProvider` for `List<Model>`. The decoders should be added to the registry by the
    /// plugin as part of its configuration steps. By delegating responsibility to the `ModelListDecoder`, it is up to
    /// the plugin to successfully return an instance of `ModelListProvider`.
    required convenience public init(from decoder: Decoder) throws {
        for listDecoder in ModelListDecoderRegistry.listDecoders.get() {
            if listDecoder.shouldDecode(modelType: ModelType.self, decoder: decoder) {
                let listProvider = try listDecoder.makeListProvider(modelType: ModelType.self, decoder: decoder)
                self.init(listProvider: listProvider)
                return
            }
        }
        let json = try JSONValue(from: decoder)
        if case .array = json {
            let elements = try [Element](from: decoder)
            self.init(elements: elements)
        } else {
            self.init()
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded:
            try [Element]().encode(to: encoder)
        case .loaded(let elements):
            try elements.encode(to: encoder)
        }
    }
}
