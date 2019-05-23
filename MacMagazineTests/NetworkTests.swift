//
//  NetworkTests.swift
//  MacMagazineTests
//
//  Created by Cassio Rossi on 23/05/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import XCTest

// Tests to be performed:
// 1) Get Posts from Wordpress
// 2) Test that the proper XML was retrieved
// 3) Create a mock test
// 4) Test for the content of the mock data, adding to the XMLPost class

class NetworkTests: XCTestCase {

	override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

	override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNetworkGetShouldReturnAnyData() {
		let expectation = self.expectation(description: "Testing Network for any Data...")
		expectation.expectedFulfillmentCount = 1

		getPosts { data in
			XCTAssertNotNil(data, "Network response should not be nil")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error, "Error occurred: \(String(describing: error))")
		}
    }

	func testNetworkGetShouldReturnValidData() {
		let expectation = self.expectation(description: "Testing Network for a valid Data...")
		expectation.expectedFulfillmentCount = 1
		
		getPosts { data in
			XCTAssertNotNil(data, "Network response should not be nil")
			guard let xmlResponse = data?.toString() else {
				XCTFail("Data should not be nil")
				return
			}
			XCTAssertNotNil(xmlResponse, "Data should not be nil")
			XCTAssertTrue(xmlResponse.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"), "Response should be a valid XML")
			XCTAssertTrue(xmlResponse.contains("<atom:link href=\"https://macmagazine.uol.com.br/feed/?paged=0\" rel=\"self\" type=\"application/rss+xml\" />"), "Response should come from a valid source")

			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error, "Error occurred: \(String(describing: error))")
		}
	}

	func testAPIReturnAnyData() {
		let expectation = self.expectation(description: "Testing API for any Data...")
		expectation.expectedFulfillmentCount = 1

		// After getting the XML file from Wordpress, each XML parse call the closure to continue
		// When the parse ended, a nil is returned back to the closure
		API().getPosts(page: 0) { post in
			guard let _ = post else {
				XCTAssertNil(post, "API response after parse must be nil")
				expectation.fulfill()
				return
			}
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error, "Error occurred: \(String(describing: error))")
		}
	}

	func testAPIReturnValidData() {
		let expectation = self.expectation(description: "Testing API for a valid Data...")
		expectation.expectedFulfillmentCount = 1
		
		// After getting the XML file from Wordpress, each XML parse call the closure to continue
		// When the parse ended, a nil is returned back to the closure
		API().getPosts(page: 0) { post in
			guard let post = post else {
				expectation.fulfill()
				return
			}
			XCTAssertNotEqual(post.title, "", "API response title should not be nil")
			XCTAssertNotEqual(post.link, "", "API response title should not be nil")
			XCTAssertNotEqual(post.pubDate, "", "API response title should not be nil")
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error, "Error occurred: \(String(describing: error))")
		}
	}

}

extension NetworkTests {

	fileprivate func getHost() -> URL? {
		let feed = "https://macmagazine.uol.com.br/feed/"
		let paged = "paged=0"

		let host = "\(feed)?\(paged)"
		guard let url = URL(string: "\(host.escape())") else {
			return nil
		}
		return url
	}

	fileprivate func getPosts(_ completion: @escaping (Data?) -> Void) {
		guard let url = getHost() else {
			return
		}
		Network.get(url: url) { (data: Data?, _: String?) in
			completion(data)
		}
	}

}

extension Data {
	func toString() -> String {
		guard let string = String(data: self, encoding: String.Encoding.utf8) else {
			return ""
		}
		return string
	}
}
