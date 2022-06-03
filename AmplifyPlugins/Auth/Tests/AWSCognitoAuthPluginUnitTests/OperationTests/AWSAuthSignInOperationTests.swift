//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

import AWSCognitoIdentityProvider

class AWSAuthSignInOperationTests: XCTestCase {

    var queue: OperationQueue?
    let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue?.maxConcurrentOperationCount = 1
    }
    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    func testSRPSignInOperationSuccess() throws {
        let exp = expectation(description: #function)
        let functionExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            functionExpectation.fulfill()
            return .init(challengeName: .passwordVerifier,
                         challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                         session: "somesession" )
        }

        let respondToChallenge: MockIdentityProvider.MockRespondToAuthChallengeResponse = { _ in
            return .init(authenticationResult:  .init(accessToken: "accesToken",
                                                      expiresIn: 2,
                                                      idToken: "idToken",
                                                      refreshToken: "refreshToken"))

        }

        let request = AuthSignInRequest(username: "username",
                                        password: "password",
                                        options: AuthSignInRequest.Options())

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(
                mockInitiateAuthResponse: initiateAuth,
                mockRespondToAuthChallengeResponse: respondToChallenge
            )})
        let operation = AWSAuthSignInOperation(
            request,
            authStateMachine: statemachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine()) {  result in
                switch result {
                case .success(let signUpResult):
                    print("Sign In Result: \(signUpResult)")
                case .failure(let error):
                XCTAssertNil(error, "Error should not be returned")
            }
            exp.fulfill()
        }
        queue?.addOperation(operation)
        wait(for: [exp, functionExpectation], timeout: 2)

    }


}
