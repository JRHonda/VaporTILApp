//
//  CreateCatgeory.swift
//  
//
//  Created by Justin Honda on 5/7/22.
//

import Fluent
import Vapor

struct CreateCategory: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories").delete()
    }

}
