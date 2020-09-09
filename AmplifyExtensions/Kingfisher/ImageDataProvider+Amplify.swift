//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Amplify) && canImport(Kingfisher)

import Amplify
import Kingfisher

/// `ImageDataProvider` implementation that loads images using `Amplify.Storage`.
public struct AmplifyImageProvider: ImageDataProvider {
    public let key: String
    public let accessLevel: StorageAccessLevel

    public var cacheKey: String {
        "\(accessLevel.rawValue)/\(key)"
    }

    public func data(handler: @escaping (Result<Data, Error>) -> Void) {
        Amplify.Logging.verbose("""
        Kingfisher will load an image using Amplify.Storage with key \(cacheKey) and access level \(accessLevel)
        """)
        let options = StorageDownloadDataRequest.Options(accessLevel: accessLevel)
        _ = Amplify.Storage.downloadData(key: key, options: options) { result in
            switch result {
            case .success(let data):
                Amplify.Logging.verbose("Success loading image data for Kingfisher using Amplify.Storage")
                handler(.success(data))
            case .failure(let error):
                Amplify.Logging.error(error: error)
                handler(.failure(error))
            }
        }
    }
}

extension Source {

    /// Returns a `.provider(ImageDataProvider)` setup with the Amplify integration.
    ///
    /// UIKit example:
    ///
    /// ```swift
    /// let imageView = ImageView()
    /// imageView.kf.setImage(with: .amplify(key: "myimage", accessLevel: .guest))
    /// ```
    ///
    /// SwiftUI example:
    ///
    /// ```swift
    /// VStack {
    ///     KFImage(source: .amplify(key: "myimage", accessLevel: .guest))
    /// }
    /// ```
    ///
    /// - Parameters
    ///   - key: the stored image identifier.
    ///   - accessLevel: the access level (defaults to `.guest`)
    /// - Returns: `.provider(ImageDataProvider)` using `AmplifyImageProvider`
    public static func amplify(key: String, accessLevel: StorageAccessLevel = .guest) -> Source {
        return .provider(AmplifyImageProvider(key: key, accessLevel: accessLevel))
    }

}

#endif
