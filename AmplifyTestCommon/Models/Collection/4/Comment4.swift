//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment4: Model {
  public let id: String
  public var content: String
  public var post: Post4?

  public init(id: String = UUID().uuidString,
      content: String,
      post: Post4? = nil) {
      self.id = id
      self.content = content
      self.post = post
  }
}

@propertyWrapper public struct Lazy<ModelType: Model>: Codable, LazyModelMarker {
    public var id: String {
        get { lazyModel.id }
        set { lazyModel.id = newValue }
    }

    public var lazyModel: LazyModel<ModelType>

    public var wrappedValue: ModelType? {
        get { lazyModel.instance }
        set { lazyModel.instance = newValue }
    }

    public init(id: String) {
        self.lazyModel = .init(id: id)
    }

    public init(wrappedValue: ModelType?) {
        if let wrappedValue = wrappedValue {
            self.lazyModel = .init(wrappedValue)
            self.id = wrappedValue.id
        } else {
            self.lazyModel = .init(id: "123")
        }
    }

    public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)
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
}

public struct Comment4a: Model {
    public let id: String
    public var content: String
    @Lazy<Post4a> public var post: Post4a?

    public init(id: String = UUID().uuidString, content: String, post: Post4a? = nil) {
        self.id = id
        self.content = content
        self.post = post
    }
}
