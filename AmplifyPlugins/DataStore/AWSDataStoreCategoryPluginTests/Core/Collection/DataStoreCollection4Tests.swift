//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/*
 (Belongs to) A connection that is bi-directional by adding a many-to-one connection to the type that already have a one-to-many connection.
 ```
 type Post4 @model {
   id: ID!
   title: String!
   comments: [Comment4] @connection(keyName: "byPost4", fields: ["id"])
 }

 type Comment4 @model
   @key(name: "byPost4", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   content: String!
   post: Post4 @connection(fields: ["postID"])
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */

class DataStoreCollection4Tests: BaseDataStoreTests {

    func test1() {
        print(Post4.schema.sortedFields)
        print(Post4.schema.columns)

        print(Comment4.schema.sortedFields)
        print(Comment4.schema.columns)
    }

    func test2() {
        let post = Post4(title: "title")
        let comment = Comment4(content: "Comment 1", post: .init(post))

        let commentInsertStatement = InsertStatement(model: comment, modelSchema: Comment4.schema)
        print(commentInsertStatement.stringValue)
        print(commentInsertStatement.variables)
    }

    func testLazyLoadPostFromComment() {
        let savePostSuccess = expectation(description: "save post successful")
        let post = Post4(title: "title")
        storageAdapter.save(post) {
            switch $0 {
            case .success(let post):
                print(post)
                savePostSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [savePostSuccess], timeout: 1)
        let saveCommentSuccess = expectation(description: "save comment successful")

        let comment = Comment4(content: "Comment 1", post: .init(post))
        storageAdapter.save(comment) {
            switch $0 {
            case .success(let comment):
                print(comment)

                guard let lazyPost = comment.post else {
                    XCTFail("Post is nil")
                    return
                }

                XCTAssertEqual(lazyPost.id, post.id)
                // Load the post
                XCTAssertEqual(lazyPost.instance?.title, post.title)
                saveCommentSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveCommentSuccess], timeout: 100)
    }

    func testLazyLoadCommentsFromPost() {
        let savePostSuccess = expectation(description: "save post successful")
        let post = Post4(title: "title")
        storageAdapter.save(post) {
            switch $0 {
            case .success(let post):
                print(post)
                savePostSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [savePostSuccess], timeout: 1)
        let saveCommentSuccess = expectation(description: "save comment successful")

        let comment = Comment4(content: "Comment 1", post: .init(post))
        storageAdapter.save(comment) {
            switch $0 {
            case .success(let comment):
                print(comment)
                saveCommentSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveCommentSuccess], timeout: 100)

        let queryLazyCommentsFromPostSuccess = expectation(description: "query lazy comments from post successful")
        storageAdapter.query(Post4.self, predicate: Post4.keys.id == post.id) { result in
            switch result {
            case .success(let posts):
                guard let firstPost = posts.first else {
                    XCTFail("Could not retrieve post by id \(post.id)")
                    return
                }
                guard let comments = firstPost.comments else {
                    XCTFail("Could not retrieve comments from post")
                    return
                }
                // Load the comments
                XCTAssertEqual(comments.count, 1)
                queryLazyCommentsFromPostSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [queryLazyCommentsFromPostSuccess], timeout: 100)
    }
}
