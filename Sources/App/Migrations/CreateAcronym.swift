//
//  CreateAcronym.swift
//
//
//  Created by Tim Bryant on 6/20/24.
//

import Fluent
import Foundation

struct CreateAcronym: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("acronyms")
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("acronyms").delete()
    }
}
