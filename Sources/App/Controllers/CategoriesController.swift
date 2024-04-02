//
//  CategoriesController.swift
//  
//
//  Created by Justin Honda on 5/7/22.
//

import Fluent
import Vapor

struct CategoriesController: RouteCollection {

    // MARK: - RouteBuilder

    func boot(routes: RoutesBuilder) throws {
        let categoriesRoute = routes.grouped("api", "categories")

        // GET
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(":categoryID", use: getHandler)
        categoriesRoute.get(":categoryID", "acronyms", use: getAcronymsHandler)

        // POST
        categoriesRoute.post(use: createHandler)
    }

    // MARK: - GET

    func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
        Category.query(on: req.db).all()
    }

    func getHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func getAcronymsHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$acronyms.get(on: req.db)
            }

    }

    // MARK: - POST

    func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let category = try req.content.decode(Category.self)

        return category
            .save(on: req.db)
            .map { category }
    }


}
