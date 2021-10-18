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

public struct Comment4a: Model {
    public let id: String
    public var content: String
    private var _post: LazyModel<Post4>?
    
    public var post: Post4? {
        get {
            _post?.instance
        }
        set {
            _post?.instance = newValue
        }
    }
    
    public init(id: String = UUID().uuidString,
                content: String,
                post: Post4? = nil) {
        self.id = id
        self.content = content
        if let post = post {
            self._post = .init(post)
        }
    }
}
