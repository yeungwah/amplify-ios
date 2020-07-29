//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Amplify) && canImport(Kingfisher)

import Amplify
import Kingfisher

public struct AmplifyImageProvider: ImageDataProvider {
    public let cacheKey: String
    public let accessLevel: StorageAccessLevel

    public func data(handler: @escaping (Result<Data, Error>) -> Void) {
        let options = StorageDownloadDataRequest.Options(accessLevel: accessLevel)
        _ = Amplify.Storage.downloadData(key: cacheKey, options: options) { result in
            switch result {
            case .success(let data):
                handler(.success(data))
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
}

extension Source {

    public static func amplify(key: String, accessLevel: StorageAccessLevel = .guest) -> Source {
        return .provider(AmplifyImageProvider(cacheKey: key, accessLevel: accessLevel))
    }

}

#endif
