//
//  CreateCategory.swift
//
//
//  Created by Tim Bryant on 6/21/24.
//

import Fluent
import Foundation

struct CreateCategory: Migration {
    func prepare(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema("categories")
            .id()
            .field("name", .string, .required)
            .create()
    }
    
    func revert(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema("categories").delete()
    }
}
