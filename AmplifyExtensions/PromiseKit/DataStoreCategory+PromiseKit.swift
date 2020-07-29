//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_exported import Amplify
#if !PMKCocoaPods
import PromiseKit
#endif

private extension Resolver where T: Any {
    var asCompletionCallback: DataStoreCallback<T> {
        return {
            switch $0 {
            case let .success(result):
                self.fulfill(result)
            case let .failure(error):
                self.reject(error)
            }
        }
    }
}

public extension DataStoreCategory {

    func save<M: Model>(_ model: M, where predicate: QueryPredicate? = nil) -> Promise<M> {
        return Promise { seal in
            self.save(model, where: predicate, completion: seal.asCompletionCallback)
        }
    }

    func query<M: Model>(_ modelType: M.Type, byId id: String) -> Promise<M?> {
        return Promise { seal in
            self.query(modelType, byId: id, completion: seal.asCompletionCallback)
        }
    }

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate? = nil,
                         paginate paginationInput: QueryPaginationInput? = nil) -> Promise<[M]> {
        return Promise { seal in
            self.query(modelType,
                       where: predicate,
                       paginate: paginationInput,
                       completion: seal.asCompletionCallback)
        }
    }

    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate? = nil) -> Promise<Void> {
        return Promise { seal in
            self.delete(model, where: predicate, completion: seal.asCompletionCallback)
        }
    }

    func delete<M: Model>(_ modelType: M.Type, withId id: String) -> Promise<Void> {
        return Promise { seal in
            self.delete(modelType, withId: id, completion: seal.asCompletionCallback)
        }
    }

    func clear() -> Promise<Void> {
        return Promise { seal in
            self.clear(completion: seal.asCompletionCallback)
        }
    }

}
