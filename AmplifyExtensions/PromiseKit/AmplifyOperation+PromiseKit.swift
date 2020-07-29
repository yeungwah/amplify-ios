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

public extension AmplifyOperation {

//    func then() -> Promise<Success> {
//
//    }

    var promise: Promise<Success> {
        return Promise { seal in
            _ = Amplify.Hub.listenForResult(to: self) {
                switch $0 {
                case .success(let result):
                    seal.fulfill(result)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

}

func test() {
    Amplify.Storage.getURL(key: "", resultListener: { _ in
        
    })
    .promise
    .map(on: .main) { url in
        print(url)
    }
    .catch { error in
        print(error)
    }
}
