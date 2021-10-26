//
//  CreateTokens.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 16..
//

import Fluent

struct CreateTokens: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema)
            .id()
            .field("user_id", .uuid, .references("users", "id"))
            .field("value", .string, .required)
            .unique(on: "value")
            .field("source", .uuid, .required)
            .field("created_at", .datetime, .required)
            .field("expires_at", .datetime)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema).delete()
    }
}
