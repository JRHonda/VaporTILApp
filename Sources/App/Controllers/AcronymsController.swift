//
//  AcronymsController.swift
//  
//
//  Created by Justin Honda on 5/7/22.
//

import Vapor
import Fluent

struct AcronymsController: RouteCollection {

    // MARK: - RouteBuilder

    func boot(routes: RoutesBuilder) throws {
        let acronymsRoutes = routes.grouped("api", "acronyms")

        // GET
        acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.get(":acronymID", use: getHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get(":acronymID", "categories", use: getCategoriesHandler)

        // POST
        acronymsRoutes.post(use: createHandler)
        acronymsRoutes.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)

        // PUT
        acronymsRoutes.put(":acronymID", use: updateHandler)

        // DELETE
        acronymsRoutes.delete(":acronymID", use: deleteHandler)
        acronymsRoutes.delete(":acronymID", "categories", ":acronymID", use: removeCategoriesHandler)
    }

    // MARK: - GET

    func getUserHandler(_ req: Request) -> EventLoopFuture<User> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db)
            }
    }

    func getAllHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
        Acronym.query(on: req.db).all()
    }

    func getHandler(_ req: Request) -> EventLoopFuture<Acronym> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func getFirstHandler(_ req: Request) -> EventLoopFuture<Acronym> {
        return Acronym.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }

    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
    }

    func sortedHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
        return Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
    }

    func getCategoriesHandler(_ req: Request) -> EventLoopFuture<[Category]> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$categories.query(on: req.db).all()
            }
    }

    // MARK: - POST

    func createHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let data = try req.content.decode(CreateAcronymData.self)
        
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)

        return acronym.save(on: req.db).map { acronym }
    }

    func addCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))

        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))

        return acronymQuery.and(categoryQuery)
            .flatMap { acronym, category in
                acronym
                    .$categories
                    .attach(category, on: req.db)
                    .transform(to: .created)
            }
    }

    func removeCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))

        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))

        return acronymQuery.and(categoryQuery)
            .flatMap { acronym, category in
                acronym
                    .$categories
                    .detach(category, on: req.db)
                    .transform(to: .noContent)
            }
    }

    // MARK: - PUT

    func updateHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let updateData = try req.content.decode(CreateAcronymData.self)

        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.short = updateData.short
                acronym.long = updateData.long
                acronym.$user.id = updateData.userID
                return acronym.save(on: req.db).map {
                    acronym
                }
            }
    }

    // MARK: - DELETE

    func deleteHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }

}

struct CreateAcronymData: Content {
    let short: String
    let long: String
    let userID: UUID
}
