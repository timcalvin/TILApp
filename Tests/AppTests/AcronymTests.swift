//
//  AcronymTests.swift
//
//
//  Created by Tim Bryant on 6/24/24.
//

@testable import App
import XCTVapor

final class AcronymTests: XCTestCase {
    var app: Application!
    
    let acronymsURI = "/api/acronyms/"
    let acronymShort = "OMG"
    let acronymLong = "Oh My God"
    
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
    
    func testAcronymsCanBeRetrievedFromAPI() async throws {
        let acronym1 = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        _ = try await Acronym.create(on: app.db)
        
        try app.test(.GET, acronymsURI) { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
            XCTAssertEqual(acronyms[0].id, acronym1.id)
        }
    }
    
    func testAcronymCanBeSavedWithAPI() async throws {
        let user = try await User.create(on: app.db)
        let createAcronymData = CreateAcronymData(short: acronymShort, long: acronymLong, userID: user.id!)
        
        try app.test(.POST, acronymsURI, beforeRequest: { request in
            try request.content.encode(createAcronymData)
        }, afterResponse: { response in
            let receivedAcronym = try response.content.decode(Acronym.self)
            
            XCTAssertEqual(receivedAcronym.short, acronymShort)
            XCTAssertEqual(receivedAcronym.long, acronymLong)
            XCTAssertNotNil(receivedAcronym.id)
            
            try app.test(.GET, acronymsURI) { allAcronymsResponse in
                let acronyms = try allAcronymsResponse.content.decode([Acronym].self)
                
                XCTAssertEqual(acronyms.count, 1)
                XCTAssertEqual(acronyms[0].short, acronymShort)
                XCTAssertEqual(acronyms[0].long, acronymLong)
                XCTAssertEqual(acronyms[0].id, receivedAcronym.id)
            }
        })
    }
    
    func testGettingASingleAcronymFromTheAPI() async throws {
        let acronym = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)") { response in
            let returnedAcronym = try response.content.decode(Acronym.self)
            
            XCTAssertEqual(returnedAcronym.short, acronymShort)
            XCTAssertEqual(returnedAcronym.long, acronymLong)
            XCTAssertEqual(returnedAcronym.id, acronym.id)
        }
    }
    
    func testUpdatingAnAcronym() async throws {
        let acronym = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let newUser = try await User.create(on: app.db)
        let newLong = "Oh My Gosh"
        let updatedAcronymData = CreateAcronymData(short: acronymShort, long: newLong, userID: newUser.id!)
        
        try app.test(.PUT, "\(acronymsURI)\(acronym.id!)") { request in
            try request.content.encode(updatedAcronymData)
        }
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)") { response in
            let returnedAcronym = try response.content.decode(Acronym.self)
            
            XCTAssertEqual(returnedAcronym.short, acronymShort)
            XCTAssertEqual(returnedAcronym.long, newLong)
            XCTAssertEqual(returnedAcronym.$user.id, newUser.id)
        }
    }
    
    func testDeletingAnAcronym() async throws {
        let acronym = try await Acronym.create(on: app.db)
        
        try app.test(.GET, acronymsURI) { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 1)
        }
        
        try await app.test(.DELETE, "\(acronymsURI)\(acronym.id!)")
        
        try app.test(.GET, acronymsURI) { response in
            let newAcronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(newAcronyms.count, 0)
        }
    }
    
    func testSearchAcronymShort() async throws {
        let acronym = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)search?term=OMG") { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 1)
            XCTAssertEqual(acronyms[0].id, acronym.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        }
    }
    
    func testSearchAcronymLong() async throws {
        let acronym = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)search?term=Oh+My+God") { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 1)
            XCTAssertEqual(acronyms[0].id, acronym.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        }
    }
    
    func testGetFirstAcronym() async throws {
        let acronym = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        _ = try await Acronym.create(on: app.db)
        _ = try await Acronym.create(on: app.db)
        
        try app.test(.GET, "\(acronymsURI)first") { response in
            let firstAcronym = try response.content.decode(Acronym.self)
            
            XCTAssertEqual(firstAcronym.id, acronym.id)
            XCTAssertEqual(firstAcronym.short, acronymShort)
            XCTAssertEqual(firstAcronym.long, acronymLong)
        }
    }
    
    func testSortingAcronyms() async throws {
        let short2 = "LOL"
        let long2 = "Laugh Out Loud"
        let acronym1 = try await Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let acronym2 = try await Acronym.create(short: short2, long: long2, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)sorted") { response in
            let sortedAcronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(sortedAcronyms[0].id, acronym2.id)
            XCTAssertEqual(sortedAcronyms[1].id, acronym1.id)
        }
    }
    
    func testGettingAnAcronymsUser() async throws {
        let user = try await User.create(on: app.db)
        let acronym = try await Acronym.create(user: user, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/user") { response in
            let acronymsUser = try response.content.decode(User.self)
            
            XCTAssertEqual(acronymsUser.id, user.id)
            XCTAssertEqual(acronymsUser.name, user.name)
            XCTAssertEqual(acronymsUser.username, user.username)
        }
    }
    
    func testAcronymsCategories() async throws {
        let category = try await Category.create(on: app.db)
        let category2 = try await Category.create(name: "Funny", on: app.db)
        let acronym = try await Acronym.create(on: app.db)
        
        try await app.test(.POST, "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)")
        try await app.test(.POST, "\(acronymsURI)\(acronym.id!)/categories/\(category2.id!)")
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/categories") { response in
            let categories = try response.content.decode([App.Category].self)
            
            XCTAssertEqual(categories.count, 2)
            XCTAssertEqual(categories[0].id, category.id)
            XCTAssertEqual(categories[0].name, category.name)
            XCTAssertEqual(categories[1].id, category2.id)
            XCTAssertEqual(categories[1].name, category2.name)
        }
        
        try await app.test(.DELETE, "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)")
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/categories") { response in
            let newCategories = try response.content.decode([App.Category].self)
            
            XCTAssertEqual(newCategories.count, 1)
        }
    }
}
