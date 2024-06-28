//
//  CreateCategory.swift
//
//
//  Created by Tim Bryant on 6/21/24.
//

import Fluent
import Foundation

struct CreateCategory: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("categories")
            .id()
            .field("name", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("categories").delete()
    }
}
