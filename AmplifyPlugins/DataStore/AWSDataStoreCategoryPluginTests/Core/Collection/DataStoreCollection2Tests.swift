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

    func testSchemaFields() {
        XCTAssertEqual(Team2.schema.sortedFields.count, 2)
        XCTAssertEqual(Team2.schema.columns.count, 2)
        XCTAssertEqual(Project2.schema.sortedFields.count, 3)
        XCTAssertEqual(Project2.schema.columns.count, 3)
    }

    func testInsertStatement() {
        let team = Team2(name: "name")
        let project = Project2(name: "name", team: team)

        let teamInsertStatement = InsertStatement(model: team, modelSchema: Team2.schema)
        let expectedTeamInsertStatement = """
        insert into Team2 ("id", "name")
        values (?, ?)
        """
        XCTAssertEqual(teamInsertStatement.stringValue, expectedTeamInsertStatement)
        XCTAssertEqual(teamInsertStatement.variables.count, 2)
        XCTAssertEqual(teamInsertStatement.variables[0] as? String, team.id)
        XCTAssertEqual(teamInsertStatement.variables[1] as? String, team.name)

        let projectInsertStatement = InsertStatement(model: project, modelSchema: Project2.schema)
        let expectedProjectInsertStatement = """
        insert into Project2 ("id", "name", "teamID")
        values (?, ?, ?)
        """
        XCTAssertEqual(projectInsertStatement.stringValue, expectedProjectInsertStatement)
        XCTAssertEqual(projectInsertStatement.variables.count, 3)
        XCTAssertEqual(projectInsertStatement.variables[0] as? String, project.id)
        XCTAssertEqual(projectInsertStatement.variables[1] as? String, project.name)
        XCTAssertEqual(projectInsertStatement.variables[2] as? String, team.id)
    }

    func testUpdateStatement() {

    }

    func testDeleteStatement() {

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
                guard case .notLoaded = lazyTeam.loadedState else {
                    XCTFail("Should not be in loaded state")
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
}
