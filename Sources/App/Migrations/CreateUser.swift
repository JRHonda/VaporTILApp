//
//  CreateUser.swift
//  
//
//  Created by Justin Honda on 5/7/22.
//

import Fluent

struct CreateUser: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }

}
