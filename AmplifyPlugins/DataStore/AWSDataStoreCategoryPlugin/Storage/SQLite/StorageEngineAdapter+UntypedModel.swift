//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import SQLite

extension SQLiteStorageEngineAdapter {

    func save0(untypedModel: Model, completion: DataStoreCallback<Model>) {
        //let stopwatch = Stopwatch(start: true)
        guard let connection = connection else {
            completion(.failure(.nilSQLiteConnection()))
            return
        }

        do {
            let modelName: ModelName
            if let jsonModel = untypedModel as? JSONValueHolder,
               let modelNameFromJson = jsonModel.jsonValue(for: "__typename") as? String {
                modelName = modelNameFromJson
            } else {
                modelName = untypedModel.modelName
            }

            guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
                let error = DataStoreError.invalidModelName(modelName)
                throw error
            }

            let shouldUpdate = try exists(modelSchema, withId: untypedModel.id)

            // TODO serialize result and create a new instance of the model
            // (some columns might be auto-generated after DB insert/update)
            if shouldUpdate {
                let statement = UpdateStatement(model: untypedModel, modelSchema: modelSchema)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            } else {
                let statement = InsertStatement(model: untypedModel, modelSchema: modelSchema)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            }

            //log.debug("Total time \(stopwatch.stop())s")
            completion(.success(untypedModel))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    func saveBatch(untypedModels: [Model], completion: DataStoreCallback<Model>) {
        //let stopwatch = Stopwatch(start: true)
        guard let connection = connection else {
            completion(.failure(.nilSQLiteConnection()))
            return
        }
        guard let untypedModel = untypedModels.first else {
            completion(.failure(DataStoreError.internalOperation("", "", nil)))
            return
        }


        do {
            let modelName: ModelName
            if let jsonModel = untypedModel as? JSONValueHolder,
               let modelNameFromJson = jsonModel.jsonValue(for: "__typename") as? String {
                modelName = modelNameFromJson
            } else {
                modelName = untypedModel.modelName
            }

            guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
                let error = DataStoreError.invalidModelName(modelName)
                throw error
            }

            var shouldBatchInsertModels: [Model] = []
            for untypedModel in untypedModels {
                let shouldUpdate = try exists(modelSchema, withId: untypedModel.id)

                // TODO serialize result and create a new instance of the model
                // (some columns might be auto-generated after DB insert/update)
                if shouldUpdate {
                    let statement = UpdateStatement(model: untypedModel, modelSchema: modelSchema)
                    _ = try connection.prepare(statement.stringValue).run(statement.variables)
                } else {
                    shouldBatchInsertModels.append(untypedModel)
                    // let statement = InsertStatement(model: untypedModel, modelSchema: modelSchema)
                    //_ = try connection.prepare(statement.stringValue).run(statement.variables)
                }
            }

            if !shouldBatchInsertModels.isEmpty {
                print("Batch Saving model")
                let statement = BatchInsertStatement(models: shouldBatchInsertModels, modelSchema: modelSchema)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            }

            //log.debug("Total time \(stopwatch.stop())s")
            completion(.success(untypedModel))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    func query(modelSchema: ModelSchema,
               predicate: QueryPredicate? = nil,
               completion: DataStoreCallback<[Model]>) {
        guard let connection = connection else {
            completion(.failure(.nilSQLiteConnection()))
            return
        }
        do {
            let statement = SelectStatement(from: modelSchema, predicate: predicate)
            let rows = try connection.prepare(statement.stringValue).run(statement.variables)
            let result: [Model] = try rows.convertToUntypedModel(using: modelSchema, statement: statement)
            completion(.success(result))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

}
