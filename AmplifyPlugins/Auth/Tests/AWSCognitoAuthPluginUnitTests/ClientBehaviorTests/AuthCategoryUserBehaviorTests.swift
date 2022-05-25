//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AuthCategoryUserBehaviorTests: XCTestCase {

    func testGetUserUserWhileNotConfigured() throws {
        let authState: AuthState = .notConfigured
        let plugin = try createPlugin(authState: authState)

        let user = plugin.getCurrentUser()

        XCTAssertNil(user)
    }

    func testGetUserUserWhileNotConfiguredAsync() async throws {
        let authState: AuthState = .notConfigured
        let plugin = try createPlugin(authState: authState)

        let user = await plugin.getCurrentUserAsync()

        XCTAssertNil(user)
    }

    func testGetCurrentUser() throws {
        let userId = "abc123"
        let userName = "xyz987"
        let authState = Defaults.makeAuthState(userId: userId, userName: userName)
        let plugin = try createPlugin(authState: authState)

        let user = plugin.getCurrentUser()

        XCTAssertNotNil(user)
        XCTAssertEqual(user?.userId, userId)
        XCTAssertEqual(user?.username, userName)
    }

    func testGetCurrentUserAsync() async throws {
        let userId = "xyz987"
        let userName = "abc123"
        let authState = Defaults.makeAuthState(userId: userId, userName: userName)
        let plugin = try createPlugin(authState: authState)

        let user = await plugin.getCurrentUserAsync()
        
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.userId, userId)
        XCTAssertEqual(user?.username, userName)
    }

    private func createPlugin(authState: AuthState,
                              file: StaticString = #filePath,
                              line: UInt = #line) throws -> AWSCognitoAuthPlugin {
        let plugin = AWSCognitoAuthPlugin()
        plugin.authStateMachine = MockAuthStateMachine(authState: authState)

        return plugin
    }
}
