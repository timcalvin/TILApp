//
//  AcronymsController.swift
//
//
//  Created by Tim Bryant on 6/21/24.
//

import Fluent
import Foundation
import Vapor

struct AcronymsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // route groups
        let acronymsRoutes = routes.grouped("api", "acronyms")
        
        // create an acronym
        acronymsRoutes.post(use: createHandler)
        
        // retrieve all acronyms
        acronymsRoutes.get(use: getAllHandler)
        
        // get acronym by id
        acronymsRoutes.get(":acronymID", use: getHandler)
        
        // update the acronym with the given id
        acronymsRoutes.put(":acronymID", use: updateHandler)
        
        // delete the acronym with the given id
        acronymsRoutes.delete(":acronymID", use: deleteHandler)
        
        // search the acronyms
        acronymsRoutes.get("search", use: searchHandler)
        
        // return the first acronym
        acronymsRoutes.get("first", use: getFirstHandler)
        
        // return a list of all acronyms sorted alphabetically by short property
        acronymsRoutes.get("sorted", use: sortedHandler)
        
        // get user id for acronym
        acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
        
        // add categories to an acronym
        acronymsRoutes.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
        
        // get categories for an acronym
        acronymsRoutes.get(":acronymID", "categories", use: getCategoriesHandler)
        
        // delete category ID from acronym ID
        acronymsRoutes.delete(":acronymID", "categories", ":categoryID", use: removeCategoriesHandler)
    }
    
    // MARK: - handelrs
    @Sendable
    func createHandler(_ req: Request) async throws -> Acronym {
        let data = try req.content.decode(CreateAcronymData.self)
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        try await acronym.save(on: req.db)
        return acronym
    }
    
    @Sendable
    func getAllHandler(_ req: Request) async throws -> [Acronym] {
        try await Acronym.query(on: req.db).all()
    }
    
    @Sendable
    func getHandler(_ req: Request) async throws -> Acronym {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return acronym
    }
    
    @Sendable
    func updateHandler(_ req: Request) async throws -> Acronym {
        let updatedData = try req.content.decode(CreateAcronymData.self)
        
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        acronym.short = updatedData.short
        acronym.long = updatedData.long
        acronym.$user.id = updatedData.userID
        
        try await acronym.save(on: req.db)
        
        return acronym
    }
    
    @Sendable
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await acronym.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func searchHandler(_ req: Request) async throws -> [Acronym] {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return try await Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
    }
    
    @Sendable
    func getFirstHandler(_ req: Request) async throws -> Acronym {
        guard let acronym = try await Acronym.query(on: req.db).first() else {
            throw Abort(.notFound)
        }
        return acronym
    }
    
    @Sendable
    func sortedHandler(_ req: Request) async throws -> [Acronym] {
        try await Acronym.query(on: req.db)
            .sort(\.$short, .ascending).all()
    }
    
    @Sendable
    func getUserHandler(_ req: Request) async throws -> User {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await acronym.$user.get(on: req.db)
    }
    
    // FIXME: - convert to async / await
    @Sendable
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
    
    @Sendable
    func getCategoriesHandler(_ req: Request) async throws -> [Category] {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await acronym.$categories.query(on: req.db).all()
    }
    
    // FIXME: - convert to async / await
    @Sendable
    func removeCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))

        return acronymQuery.and(categoryQuery).flatMap { acronym, category in
                acronym
                    .$categories
                    .detach(category, on: req.db)
                    .transform(to: .noContent)
            }
    }
}

struct CreateAcronymData: Content {
    let short: String
    let long: String
    let userID: UUID
}
