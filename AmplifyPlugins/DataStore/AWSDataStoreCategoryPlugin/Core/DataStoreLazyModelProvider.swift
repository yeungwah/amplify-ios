//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class DataStoreLazyModelProvider<Element: Model>: LazyModelProvider {
    public var id: String? {
        switch loadedState {
        case .notLoaded(let id):
            return id
        case .loaded(let id, _):
            return id
        }
    }

    /// The current state of the lazily loaded model
    enum LoadedState {

        case notLoaded(id: Model.Identifier?)

        case loaded(id: Model.Identifier, Element?)
    }

    var loadedState: LoadedState

    init(id: Model.Identifier?) {
        self.loadedState = .notLoaded(id: id)
    }

    init(element: Element) {
        self.loadedState = .loaded(id: element.id, element)
    }

    public func load() -> Result<Element?, CoreError> {
        let semaphore = DispatchSemaphore(value: 0)
        var loadResult: Result<Element?, CoreError> =
            .failure(CoreError.loadOperation("Failed to Query DataStore.",
                                             "See underlying DataStoreError for more details.",
                                             nil))

        load { result in
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

    public func load(completion: @escaping (Result<Element?, CoreError>) -> Void) {
        switch loadedState {
        case .loaded(_, let element):
            completion(.success(element))
        case .notLoaded(let id):
            guard let id = id else {
                completion(.success(nil))
                return
            }
            Amplify.DataStore.query(Element.self, byId: id) {
                switch $0 {
                case .success(let instance):
                    completion(.success(instance))
                case .failure(let error):
                    Amplify.DataStore.log.error(error: error)
                    completion(
                        .failure(CoreError.loadOperation("Failed to Query DataStore.",
                                                         "See underlying DataStoreError for more details.",
                                                         nil)))
                }
            }
        }
    }
}
