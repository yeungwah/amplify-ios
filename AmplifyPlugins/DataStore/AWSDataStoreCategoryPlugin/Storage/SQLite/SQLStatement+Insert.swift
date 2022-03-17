//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Represents a `insert` SQL statement associated with a `Model` instance.
struct InsertStatement: SQLStatement {
    let modelSchema: ModelSchema
    let variables: [Binding?]

    init(model: Model, modelSchema: ModelSchema) {
        self.modelSchema = modelSchema
        self.variables = model.sqlValues(for: modelSchema.columns, modelSchema: modelSchema)
    }

    var stringValue: String {
        let fields = modelSchema.columns
        let columns = fields.map { $0.columnName() }
        var statement = "insert into \"\(modelSchema.name)\" "
        statement += "(\(columns.joined(separator: ", ")))\n"

        let variablePlaceholders = Array(repeating: "?", count: columns.count).joined(separator: ", ")
        statement += "values (\(variablePlaceholders))"

        return statement
    }
}

struct BatchInsertStatement0: SQLStatement {
    let modelSchema: ModelSchema
    let variables: [Binding?]

    init(model1: Model, model2: Model, modelSchema: ModelSchema) {
        self.modelSchema = modelSchema

        var variables1 = model1.sqlValues(for: modelSchema.columns, modelSchema: modelSchema)
        let variables2 = model2.sqlValues(for: modelSchema.columns, modelSchema: modelSchema)
        variables1.append(contentsOf: variables2)
        self.variables = variables1
    }

    var stringValue: String {
        let statement = """
        insert into "Post" ("id", "content", "createdAt", "title", "updatedAt", "authorID")
        values
        (?, ?, ?, ?, ?, ?),
        (?, ?, ?, ?, ?, ?)
        """
        return statement
    }
}
struct BatchInsertStatement: SQLStatement {
    let modelSchema: ModelSchema
    let variables: [Binding?]
    let modelCount: Int
    init(models: [Model], modelSchema: ModelSchema) {
        self.modelSchema = modelSchema
        self.variables = models.flatMap { model in
            model.sqlValues(for: modelSchema.columns, modelSchema: modelSchema)
        }
        self.modelCount = models.count
    }

    var stringValue: String {
        let fields = modelSchema.columns
        let columns = fields.map { $0.columnName() }
        var statement = "insert into \"\(modelSchema.name)\" "
        statement += "(\(columns.joined(separator: ", ")))\n"

        statement += "values "
        let variablePlaceholders = Array(repeating: "?", count: columns.count).joined(separator: ", ")
        let completeVariable = "(\(variablePlaceholders))"
        let total = Array(repeating: completeVariable, count: modelCount).joined(separator: ",")
        statement += total

        return statement
    }
}
