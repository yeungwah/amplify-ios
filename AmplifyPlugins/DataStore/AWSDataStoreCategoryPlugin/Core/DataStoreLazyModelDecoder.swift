//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct DataStoreLazyModelDecoder: LazyModelDecoder {
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type,
                                                      decoder: Decoder) -> Bool {
        guard let json = try? JSONValue(from: decoder) else {
            return false
        }

        return shouldDecode(json: json)
    }

    static func shouldDecode(json: JSONValue) -> Bool {
        if case let .object(data) = json {
            return true
        }

        return false
    }
    public static func makeProvider<ModelType: Model>(modelType: ModelType.Type,
                                                      decoder: Decoder) throws -> AnyLazyModelProvider<ModelType> {
        if let provider = try getDataStoreLazyModelProvider(modelType: modelType, decoder: decoder) {
            return provider.eraseToAnyLazyModelProvider()
        }

        return DataStoreLazyModelProvider<ModelType>(id: nil).eraseToAnyLazyModelProvider()
    }

    static func getDataStoreLazyModelProvider<ModelType: Model>(
        modelType: ModelType.Type,
        decoder: Decoder) throws -> DataStoreLazyModelProvider<ModelType>? {

            let json = try? JSONValue(from: decoder)
            switch json {
            case .object(let model):
                if model.count == 1, case let .string(id) = model["id"] {
                    return DataStoreLazyModelProvider<ModelType>(id: id)
                }

                let container = try decoder.singleValueContainer()
                let model = try container.decode(ModelType.self)
                return DataStoreLazyModelProvider<ModelType>(element: model)
            default:
                let message = "DataStoreListProvider could not be created from \(String(describing: json))"
                Amplify.DataStore.log.error(message)
                assert(false, message)
                return nil
            }
        }
}
