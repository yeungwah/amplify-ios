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


class DataStoreListProviderFunctionalTests: BaseDataStoreTests {

    func test00() {

    }
    func test0() {
        sleep(10)
        let clearDone = expectation(description: "clearDone")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                clearDone.fulfill()
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [clearDone], timeout: 3)
    }

    func test3() {

    }

    func test1() {
        //Amplify.DataStore.clear()
        let savePostSuccess = expectation(description: "save post successful")
        let post = Post4a(title: "title")

//        if let list = post.comments {
//            list.elements.append(comment)
//        }

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
        let comment = Comment4a(content: "Comment 1", post: post)
        storageAdapter.save(comment) {
            switch $0 {
            case .success(let comment):
                print(comment)

                guard let postInternal = comment.post else {
                    XCTFail("Post is nil")
                    return
                }

//                guard case .notLoaded = postInternal.loadedState else {
//                    XCTFail("Should not be in loaded state")
//                    return
//                }
//
//                print("Lazy loading post... ")
//                print("Post instance: \(postInternal.instance)")
//
//                print("Post fetch..")
//                postInternal.fetch { result in
//                    switch result {
//                    case .success(let post):
//                        print("Fetched post \(post)")
//                    case .failure(let error):
//                        print("\(error)")
//                    }
//                }
//                print("Loaded state: \(postInternal.loadedState)")

                saveCommentSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveCommentSuccess], timeout: 1)

    }

    func testDataStoreListProviderWithAssociationDataShouldLoad() {
        let postId = preparePost4DataForTest()
        let provider = DataStoreListProvider<Comment4>(associatedId: postId, associatedField: "post")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let results = provider.load()
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        guard case .success(let comments) = results else {
            XCTFail("Should be .success")
            return
        }
        XCTAssertEqual(comments.count, 2)
    }

    func testDataStoreListProviderWithAssociationDataShouldLoadWithCompletion() {
        let postId = preparePost4DataForTest()
        let provider = DataStoreListProvider<Comment4>(associatedId: postId, associatedField: "post")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = expectation(description: "Load completed")
        provider.load { result in
            switch result {
            case .success(let results):
                guard case .loaded = provider.loadedState else {
                    XCTFail("Should be loaded")
                    return
                }
                XCTAssertEqual(results.count, 2)
                loadComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [loadComplete], timeout: 1)
    }

    // MARK: - Helpers

    func preparePost4DataForTest() -> Model.Identifier {
        let post = Post4(title: "title")
        populateData([post])
        populateData([
            Comment4(content: "Comment 1", post: post),
            Comment4(content: "Comment 1", post: post)
        ])
        return post.id
    }
}
