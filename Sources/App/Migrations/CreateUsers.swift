//
//  CreateUsers.swift
//  
//
//  Created by Kocka Dominik Csaba on 2021. 10. 16..
//

import Fluent

struct CreateUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("schgroup")
            .case("sir")
            .case("nyuszi")
            .case("ttny")
            .case("drwu")
            .case("fekete")
            .create()
            .flatMap { schgroup in
                database.enum("roles")
                    .case("user")
                    .case("admin")
                    .create()
                    .flatMap { roles in
                        database.schema(User.schema)
                            .id()
                            .field("username", .string, .required)
                            .unique(on: "username")
                            .field("image", .string)
                            .field("password_hash", .string, .required)
                            .field("fullname", .string, .required)
                            .field("nickname", .string)
                            .field("schgroup", schgroup, .required)
                            .field("roles", .array(of: roles))
                            .field("created_at", .datetime, .required)
                            .field("updated_at", .datetime, .required)
                            .create()
                    }
            }
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}
