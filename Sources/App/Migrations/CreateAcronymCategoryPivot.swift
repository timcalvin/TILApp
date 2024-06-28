//
//  CreateAcronymCategoryPivot.swift
//
//
//  Created by Tim Bryant on 6/21/24.
//

import Fluent
import Foundation

struct CreateAcronymCategoryPivot: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("acronym-category-pivot")
            .id()
            .field("acronymID", .uuid, .required, .references("acronyms", "id", onDelete: .cascade))
            .field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("acronym-category-pivot").delete()
    }
    
    
}
