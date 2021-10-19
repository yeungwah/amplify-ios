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
 A one-to-one connection where a project has one team,
 with a field you would like to use for the connection.
 ```
 type Project2 @model {
   id: ID!
   name: String
   teamID: ID!
   team: Team2 @connection(fields: ["teamID"])
 }

 type Team2 @model {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */

class DataStoreCollection2Tests: BaseDataStoreTests {

    func test1() {
        print(Project2.schema.sortedFields)
        print(Project2.schema.columns)
    }

    func test2() {
        let team = Team2(name: "name")
        let project = Project2(name: "name", team: team)

        let projectInsertStatement = InsertStatement(model: project, modelSchema: Project2.schema)
        print(projectInsertStatement.stringValue)
        print(projectInsertStatement.variables)
    }

    func testProjectWithTeam() throws {
        let saveTeamSuccess = expectation(description: "save team successful")
        let team = Team2(name: "name")
        storageAdapter.save(team) {
            switch $0 {
            case .success(let team):
                print(team)
                saveTeamSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveTeamSuccess], timeout: 10)

        let saveProjectSuccess = expectation(description: "save project successful")
        let project = Project2(name: "name", team: team)

        let projectInsertStatement = InsertStatement(model: project, modelSchema: Project2.schema)
        print(projectInsertStatement.stringValue)

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
        wait(for: [saveProjectSuccess], timeout: 10)

        let queryProjectSuccess = expectation(description: "query project successful")
        storageAdapter.query(Project2.self, predicate: Project2.keys.id == project.id) {
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
        wait(for: [queryProjectSuccess], timeout: 10)
    }

    func testHasOne() {
        let saveTeamSuccess = expectation(description: "save team successful")
        let team = Team2(name: "Team")
        storageAdapter.save(team) {
            switch $0 {
            case .success(let team):
                print(team)
                saveTeamSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveTeamSuccess], timeout: 1)

        let saveProjectSuccess = expectation(description: "save project successful")
        let project = Project2(name: "Project", team: team)
        storageAdapter.save(project) {
            switch $0 {
            case .success:
                saveProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [saveProjectSuccess], timeout: 1)

        let queryProjectSuccess = expectation(description: "query project successful")
        let predicate: QueryPredicate = field("id") == project.id
        storageAdapter.query(modelSchema: Project2.schema, predicate: predicate) { result in
            switch result {
            case .success(let results):
                guard let project = results.first as? Project2 else {
                    XCTFail("error querying project")
                    return
                }

                print(project)

                guard let teamInternal = project.team else {
                    XCTFail("team is nil")
                    return
                }

                guard case .notLoaded = teamInternal.loadedState else {
                    XCTFail("Should not be in loaded state")
                    return
                }

                print("Lazy loading team... ")
                print("Post instance: \(teamInternal.instance)")
                print("Loaded state: \(teamInternal.loadedState)")
                queryProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }

        wait(for: [queryProjectSuccess], timeout: 1)
    }
}
