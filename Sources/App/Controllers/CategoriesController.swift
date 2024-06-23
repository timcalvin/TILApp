//
//  CategoriesController.swift
//
//
//  Created by Tim Bryant on 6/21/24.
//

import Foundation
import Vapor

struct CategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoute = routes.grouped("api", "categories")
        
        // create categroy
        categoriesRoute.post(use: createHandler)
        
        // get all categroies
        categoriesRoute.get(use: getAllHandler)
        
        // get category from id
        categoriesRoute.get(":categoryID", use: getHandler)
        
        // get all acronyms for a category
        categoriesRoute.get(":categoryID", "acronyms", use: getAcronymsHandler)
    }
    
    @Sendable
    func createHandler(_ req: Request) async throws -> Category {
        let category = try req.content.decode(Category.self)
        try await category.save(on: req.db)
        return category
    }
    
    @Sendable
    func getAllHandler(_ req: Request) async throws -> [Category] {
        try await Category.query(on: req.db).all()
    }
    
    @Sendable
    func getHandler(_ req: Request) async throws -> Category {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return category
    }
    
    @Sendable
    func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await category.$acronyms.query(on: req.db).all()
    }
}
