//
//  CategoryTests.swift
//
//
//  Created by Tim Bryant on 6/24/24.
//

@testable import App
import XCTVapor

final class CategoryTests: XCTestCase {
    var app: Application!
    
    let categoriesURI = "/api/categories/"
    let categoryName = "Teenager"
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
    }
    
    func testCategoriesCanBeRetrievedFromAPI() async throws {
        let category = try await Category.create(name: categoryName, on: app.db)
        _ = try await Category.create(on: app.db)
        
        try app.test(.GET, categoriesURI) { response in
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, 2)
            XCTAssertEqual(categories[0].name, categoryName)
            XCTAssertEqual(categories[0].id, category.id)
        }
    }
    
    func testCategoryCanBeSavedWithAPI() throws {
        let category = Category(name: categoryName)
        
        try app.test(.POST, categoriesURI, beforeRequest: { request in
            try request.content.encode(category)
        }, afterResponse: { response in
            let receivedCategory = try response.content.decode(Category.self)
            
            XCTAssertEqual(receivedCategory.name, categoryName)
            XCTAssertNotNil(receivedCategory.id)
            
            try app.test(.GET, categoriesURI) { response in
                let categories = try response.content.decode([App.Category].self)
                
                XCTAssertEqual(categories.count, 1)
                XCTAssertEqual(categories[0].name, categoryName)
                XCTAssertEqual(categories[0].id, receivedCategory.id)
            }
        })
    }
    
    func testGettingASingleCategoryFromTheAPI() async throws {
        let category = try await Category.create(name: categoryName, on: app.db)
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)") { response in
            let returnedCategory = try response.content.decode(Category.self)
            
            XCTAssertEqual(returnedCategory.name, categoryName)
            XCTAssertEqual(returnedCategory.id, category.id)
        }
    }
    
    func testGettingACategoriesAcronymsFromTheAPI() async throws {
        let acronymShort = "OMG"
        let acronymLong = "Oh My God"
        let acronym = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let acronym2 = try await Acronym.create(on: app.db)
        
        let category = try await Category.create(name: categoryName, on: app.db)
        
        try await app.test(.POST, "/api/acronyms/\(acronym.id!)/categories/\(category.id!)")
        try await app.test(.POST, "/api/acronyms/\(acronym2.id!)/categories/\(category.id!)")
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)/acronyms") { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].id, acronym.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        }
    }
}
