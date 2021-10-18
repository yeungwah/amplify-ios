//
//  DataStoreLazyProvider.swift
//  AWSDataStoreCategoryPlugin
//
//  Created by Law, Michael on 10/18/21.
//  Copyright © 2021 Amazon Web Services. All rights reserved.
//

import Foundation

public class DataStoreLazyModelProvider<Instance : Model> : LazyModelProvider {
    
    enum LoadedState {
        case notLoaded(id: Model.Identifier)
        case loaded(Instance)
    }

    var loadedState: LoadedState

    init(_ id: Model.Identifier) {
        self.loadedState = .notLoaded(id : id)
    }

    init(_ instance : Instance) {
        self.loadedState = .loaded(instance)
    }
    
    public func fetch() -> Result<Instance, CoreError> {
        let semaphore = DispatchSemaphore(value: 0)
        var loadResult: Result<Instance, CoreError> =
            .failure(CoreError.loadOperation("Failed to Query DataStore.",
                                             "See underlying DataStoreError for more details.",
                                             nil))
        
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
    
    public func fetch(completion: (Result<Instance, CoreError>) -> Void) {
        switch loadedState {
        case .loaded(let instance):
            completion(.success(instance))
        case .notLoaded(let id):
            Amplify.DataStore.query(Instance.self, byId: id) {
                switch $0 {
                case .success(let instance):
                    completion(.success(instance!))
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
