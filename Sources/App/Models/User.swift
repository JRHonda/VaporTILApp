//
//  User.swift
//  
//
//  Created by Justin Honda on 5/7/22.
//

import Fluent
import Vapor

final class User: Model, Content {

    static let schema = "users"

    @ID
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "username")
    var username: String

    @Children(for: \.$user)
    var acronyms: [Acronym]

    init() { }

    init(id: UUID? = nil, name: String, username: String) {
        self.name = name
        self.username = username
    }
}
