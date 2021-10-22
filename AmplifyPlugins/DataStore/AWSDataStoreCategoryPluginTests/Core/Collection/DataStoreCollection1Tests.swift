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

    func testSQLStatement() {
        let team = Team1(name: "name")
        let project = Project1(name: "name", team: team)

        XCTAssertEqual(Team1.schema.sortedFields.count, 2)
        XCTAssertEqual(Team1.schema.columns.count, 2)
        XCTAssertEqual(Project1.schema.sortedFields.count, 3)
        XCTAssertEqual(Project1.schema.columns.count, 3)

        let teamInsertStatement = InsertStatement(model: team, modelSchema: Team1.schema)
        let expectedTeamInsertStatement = """
        insert into Team1 ("id", "name")
        values (?, ?)
        """
        XCTAssertEqual(teamInsertStatement.stringValue, expectedTeamInsertStatement)
        XCTAssertEqual(teamInsertStatement.variables.count, 2)
        XCTAssertEqual(teamInsertStatement.variables[0] as? String, team.id)
        XCTAssertEqual(teamInsertStatement.variables[1] as? String, team.name)

        let teamUpdateStatement = UpdateStatement(model: team, modelSchema: Team1.schema)
        let expectedTeamUpdateStatement = """
        update Team1
        set
          "name" = ?
        where "id" = ?
        """
        XCTAssertEqual(teamUpdateStatement.stringValue, expectedTeamUpdateStatement)
        XCTAssertEqual(teamUpdateStatement.variables.count, 2)
        XCTAssertEqual(teamUpdateStatement.variables[0] as? String, team.name)
        XCTAssertEqual(teamUpdateStatement.variables[1] as? String, team.id)

        let teamDeleteStatement = DeleteStatement(modelSchema: Team1.schema, withId: team.id)
        let expectedTeamDeleteStatement = """
        delete from Team1 as root
        where 1 = 1
          and "root"."id" = ?
        """
        XCTAssertEqual(teamDeleteStatement.stringValue, expectedTeamDeleteStatement)
        XCTAssertEqual(teamDeleteStatement.variables.count, 1)
        XCTAssertEqual(teamDeleteStatement.variables[0] as? String, team.id)

        let projectInsertStatement = InsertStatement(model: project, modelSchema: Project1.schema)
        let expectedProjectInsertStatement = """
        insert into Project1 ("id", "name", "project1TeamId")
        values (?, ?, ?)
        """
        XCTAssertEqual(projectInsertStatement.stringValue, expectedProjectInsertStatement)
        XCTAssertEqual(projectInsertStatement.variables.count, 3)
        XCTAssertEqual(projectInsertStatement.variables[0] as? String, project.id)
        XCTAssertEqual(projectInsertStatement.variables[1] as? String, project.name)
        XCTAssertEqual(projectInsertStatement.variables[2] as? String, team.id)

        let projectUpdateStatement = UpdateStatement(model: project, modelSchema: Project2.schema)
        let expectedProjectUpdateStatement = """
        update Project2
        set
          "name" = ?,
          "teamID" = ?
        where "id" = ?
        """
        XCTAssertEqual(projectUpdateStatement.stringValue, expectedProjectUpdateStatement)
        XCTAssertEqual(projectUpdateStatement.variables.count, 3)
        XCTAssertEqual(projectUpdateStatement.variables[0] as? String, project.name)
        XCTAssertEqual(projectUpdateStatement.variables[1] as? String, team.id)
        XCTAssertEqual(projectUpdateStatement.variables[2] as? String, project.id)

        let projectDeleteStatement = DeleteStatement(modelSchema: Project1.schema, withId: project.id)
        let expectedProjectDeleteStatement = """
        delete from Project1 as root
        where 1 = 1
          and "root"."id" = ?
        """
        XCTAssertEqual(projectDeleteStatement.stringValue, expectedProjectDeleteStatement)
        XCTAssertEqual(projectDeleteStatement.variables.count, 1)
        XCTAssertEqual(projectDeleteStatement.variables[0] as? String, project.id)
    }

    /// Saving the team and project separately
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

    /// Saving the team with the project
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

    /// Querying for a delete project should return `nil`.
    func testDeleteProject() {
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

        let deleteProjectSuccess = expectation(description: "delete project successful")
        storageAdapter.delete(Project1.self, withId: project.id) {
            switch $0 {
            case .success(let project):
                XCTAssertNil(project)
                deleteProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [deleteProjectSuccess], timeout: 100)

        let queryProjectSuccess = expectation(description: "query project (nil) successful")
        storageAdapter.query(Project1.self, predicate: Project1.keys.id == project.id) {
            switch $0 {
            case .success(let projects):
                XCTAssertTrue(projects.isEmpty)
                queryProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }

        }
        wait(for: [queryProjectSuccess], timeout: 100)
    }

    /// Querying for a project, whose team has been deleted, should lazy load an empty team
    func testDeleteTeam() {
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

        let deleteTeamSuccess = expectation(description: "delete team successful")
        storageAdapter.delete(Team1.self, withId: team.id) {
            switch $0 {
            case .success(let team):
                XCTAssertNil(team)
                deleteTeamSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
        wait(for: [deleteTeamSuccess], timeout: 100)

//        let queryTeamSuccess = expectation(description: "query team (nil) successful")
//        storageAdapter.query(Team1.self, predicate: Team1.keys.id == team.id) {
//            switch $0 {
//            case .success(let teams):
//                XCTAssertTrue(teams.isEmpty)
//                queryTeamSuccess.fulfill()
//            case .failure(let error):
//                XCTFail(error.errorDescription)
//            }
//
//        }
//        wait(for: [queryTeamSuccess], timeout: 100)
//
        // why is it that deleting the team, we cannot get the project?
        // because it is orphaned.
        let queryProjectSuccess = expectation(description: "query project successful")
        storageAdapter.query(Project1.self, predicate: Project1.keys.id == project.id) {
            switch $0 {
            case .success(let projects):
                guard let firstProject = projects.first else {
                    XCTFail("Could not get project")
                    return
                }

                XCTAssertEqual(firstProject.name, project.name)
                queryProjectSuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }

        }
        wait(for: [queryProjectSuccess], timeout: 100)
    }
}
