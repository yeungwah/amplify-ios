//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct LazyModelDecoderRegistry {
    public static var decoders = AtomicValue(initialValue: [LazyModelDecoder.Type]())

    public static func registerDecoder(_ decoder: LazyModelDecoder.Type) {
        decoders.append(decoder)
    }
}

extension LazyModelDecoderRegistry {
    static func reset() {
        decoders.set([LazyModelDecoder.Type]())
    }
}

public protocol LazyModelDecoder {
    static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool
    static func makeProvider<ModelType: Model>(
        modelType: ModelType.Type, decoder: Decoder) throws -> AnyLazyModelProvider<ModelType>
}
