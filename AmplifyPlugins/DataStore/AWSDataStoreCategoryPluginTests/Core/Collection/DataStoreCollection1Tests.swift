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
 A one-to-one connection where a project has a team.
 ```
 type Project1 @model {
   id: ID!
   name: String
   team: Team1 @connection
 }

 type Team1 @model {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details

 */

class DataStoreCollection1Tests: BaseDataStoreTests {

    func testSaveTeamAndProject() throws {
        let saveTeamSuccess = expectation(description: "save team successful")
        let team = Team1(name: "name")
        storageAdapter.save(team) {
            switch $0 {
            case .success(let team):
                print(team)
                saveTeamSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveTeamSuccess], timeout: 100)

        let saveProjectSuccess = expectation(description: "save project successful")
        let project = Project1(name: "name", team: nil)
        storageAdapter.save(project) {
            switch $0 {
            case .success(let project):
                print(project)
                saveProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveProjectSuccess], timeout: 100)

        let queryProjectSuccess = expectation(description: "query project successful")
        storageAdapter.query(Project1.self, predicate: Project1.keys.id == project.id) {
            switch $0 {
            case .success(let projects):
                guard let firstProject = projects.first else {
                    XCTFail("Could not get project")
                    return
                }
                XCTAssertNil(firstProject.team)
                queryProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [queryProjectSuccess], timeout: 100)
    }

    func testProjectWithTeam() throws {
        let saveTeamSuccess = expectation(description: "save team successful")
        let team = Team1(name: "name")
        storageAdapter.save(team) {
            switch $0 {
            case .success(let team):
                print(team)
                saveTeamSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveTeamSuccess], timeout: 100)

        let saveProjectSuccess = expectation(description: "save project successful")
        let project = Project1(name: "name", team: team)
        storageAdapter.save(project) {
            switch $0 {
            case .success(let project):
                print(project)
                guard let lazyTeam = project.team else {
                    XCTFail("Couldn't get team")
                    return
                }
                // Load the team
                XCTAssertEqual(lazyTeam.instance?.name, team.name)
                saveProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveProjectSuccess], timeout: 100)

        let queryProjectSuccess = expectation(description: "query project successful")
        storageAdapter.query(Project1.self, predicate: Project1.keys.id == project.id) {
            switch $0 {
            case .success(let projects):
                guard let firstProject = projects.first else {
                    XCTFail("Could not get project")
                    return
                }

                guard let lazyTeam = firstProject.team else {
                    XCTFail("Could not get team")
                    return
                }

                // Load the team
                XCTAssertEqual(lazyTeam.instance?.name, team.name)
                queryProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }

        }
        wait(for: [queryProjectSuccess], timeout: 100)
    }
}
