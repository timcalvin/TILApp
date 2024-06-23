//
//  UsersController.swift
//
//
//  Created by Tim Bryant on 6/21/24.
//

import Foundation
import Vapor

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        
        // create a user
        usersRoute.post(use: createHandler)
        
        // get all users
        usersRoute.get(use: getAllHandler)
        
        // get user based on id
        usersRoute.get(":userID", use: getHandler)
        
        // get acronyms for user
        usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
    }
    
    @Sendable
    func createHandler(_ req: Request) async throws -> User {
        let user = try req.content.decode(User.self)
        try await user.save(on: req.db)
        return user
    }
    
    @Sendable
    func getAllHandler(_ req: Request) async throws -> [User] {
        try await User.query(on: req.db).all()
    }
    
    @Sendable
    func getHandler(_ req: Request) async throws -> User {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return user
    }
    
    @Sendable
    func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await user.$acronyms.get(on: req.db)
    }
}
