//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyTestCommon
import Foundation

struct TestModelRegistration: AmplifyModelRegistration {

    func registerModels(registry: ModelRegistry.Type) {
        // Post and Comment
        registry.register(modelType: Post.self)
        registry.register(modelType: Comment.self)

        // Collection Scenario 1
        registry.register(modelType: Project1.self)
        registry.register(modelType: Team1.self)

        // Collection Scenario 2
        registry.register(modelType: Project2.self)
        registry.register(modelType: Team2.self)

        // Collection Scenario 3 -
        registry.register(modelType: Post3.self)
        registry.register(modelType: Comment3.self)

        // Collection Scenario 4
        registry.register(modelType: Post4.self)
        registry.register(modelType: Comment4.self)

        // Collection Scenario 5 -
        registry.register(modelType: Post5.self)
        registry.register(modelType: PostEditor5.self)
        registry.register(modelType: User5.self)

        // Collection Scenario 6 -
        registry.register(modelType: Blog6.self)
        registry.register(modelType: Post6.self)
        registry.register(modelType: Comment6.self)

        // Mock Models
        registry.register(modelType: MockSynced.self)
        registry.register(modelType: MockUnsynced.self)

        // Models for data conversion testing
        registry.register(modelType: ExampleWithEveryType.self)
    }

    let version: String = "1"

}

struct TestJsonModelRegistration: AmplifyModelRegistration {

    func registerModels(registry: ModelRegistry.Type) {

        // Post
        let id = ModelFieldDefinition.id("id").modelField
        let title = ModelField(name: "title", type: .string, isRequired: true)
        let content = ModelField(name: "content", type: .string, isRequired: true)
        let createdAt = ModelField(name: "createdAt", type: .string, isRequired: true)
        let updatedAt = ModelField(name: "updatedAt", type: .string)
        let draft = ModelField(name: "draft", type: .bool, isRequired: false)
        let rating = ModelField(name: "rating", type: .double, isRequired: false)
        let status = ModelField(name: "status", type: .string, isRequired: false)
        let comments = ModelField(name: "comments",
                                  type: .collection(of: "Comment"),
                                  isRequired: false,
                                  association: .hasMany(associatedFieldName: "post"))
        let postSchema = ModelSchema(name: "Post",
                                     pluralName: "Posts",
                                     fields: [id.name: id,
                                              title.name: title,
                                              content.name: content,
                                              createdAt.name: createdAt,
                                              updatedAt.name: updatedAt,
                                              draft.name: draft,
                                              rating.name: rating,
                                              status.name: status,
                                              comments.name: comments])

        ModelRegistry.register(modelType: DynamicModel.self,
                               modelSchema: postSchema) { (jsonString, decoder) -> Model in
            try DynamicModel.from(json: jsonString, decoder: decoder)
        }

        // Comment

        let commentId = ModelFieldDefinition.id().modelField
        let commentContent = ModelField(name: "content", type: .string, isRequired: true)
        let commentCreatedAt = ModelField(name: "createdAt", type: .dateTime, isRequired: true)
        let belongsTo = ModelField(name: "post",
                                   type: .model(name: "Post"),
                                   isRequired: true,
                                   association: .belongsTo(associatedWith: nil, targetName: "postId"))
        let commentSchema = ModelSchema(name: "Comment",
                                        pluralName: "Comments",
                                        fields: [
                                            commentId.name: commentId,
                                            commentContent.name: commentContent,
                                            commentCreatedAt.name: commentCreatedAt,
                                            belongsTo.name: belongsTo])
        ModelRegistry.register(modelType: DynamicModel.self,
                               modelSchema: commentSchema) { (jsonString, decoder) -> Model in
            try DynamicModel.from(json: jsonString, decoder: decoder)
        }
    }

    let version: String = "1"

}
