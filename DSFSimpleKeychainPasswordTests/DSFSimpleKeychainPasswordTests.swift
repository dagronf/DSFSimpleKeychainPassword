//
//  SimpleKeychainPasswordTests.swift
//  SimpleKeychainPasswordTests
//
//  Created by Darren Ford on 2/12/18.
//  MIT License
//
//  Copyright (c) 2018 Darren Ford
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import XCTest

class SimpleKeychainPasswordTests: XCTestCase {

	override func setUp()
	{
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown()
	{
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func _testDocExamples()
	{
		let service = DSFSimpleKeychain.Service("ProjectSecrets")

		let addAccountStatus = service.add(accountNamed: "AWSLoginID", password: "<password>")
		if case .success(let addAccountInfo) = addAccountStatus
		{
			print("Created account: \(addAccountInfo.account)")
		}
		else
		{
			print("Unable to create password")
			return
		}

		let allAccounts = service.accounts()
		if case .success(let accounts) = allAccounts
		{
			print("Found accounts: \(accounts)")
		}
		else
		{
			print("Unable to retrieve account information")
		}

		let retrieveStatus = service.retrieve(accountNamed: "AWSLoginID")
		guard case .success(let accountInfo) = retrieveStatus else
		{
			print("Unable to retrieve password")
			return
		}
		print("Password is \(accountInfo.password)")

		let deleteResult = service.delete(accountNamed: "AWSLoginID")
		if deleteResult != DSFSimpleKeychain.Status.success
		{
			print("Unable to delete password")
			return
		}
	}

	func _testUI()
	{
		let service = DSFSimpleKeychain.Service("SimpleKeychainPassword")

		let result = service.addGenericPassword()
		if case .success(let accountInfo) = result
		{
			_ = service.delete(password: accountInfo)
		}
	}

	func testReadNonExistent()
	{
		let service = DSFSimpleKeychain.Service("SimpleKeychainPassword")

		let result = service.retrieve(accountNamed: "dog")
		if case .failure(let error) = result
		{
			XCTAssertEqual(error, DSFSimpleKeychain.Status.notFound)
		}
		else
		{
			XCTAssert(false)
		}
	}

	func testDeleteNonExistent()
	{
		let service = DSFSimpleKeychain.Service("SimpleKeychainPassword")
		let result = service.delete(accountNamed: "dog")
		XCTAssertEqual(DSFSimpleKeychain.Status.notFound, result)
	}

	func testCreate()
	{
		let service = DSFSimpleKeychain.Service("SimpleKeychainPassword")
		var status = service.add(accountNamed: "dog", password: "securepassword")
		guard case .success(let password1) = status else
		{
			XCTAssert(false)
			return
		}

		status = service.add(accountNamed: "cat", password: "securecatword")
		guard case .success(let password2) = status else
		{
			XCTAssert(false)
			return
		}

		let result = service.accounts()
		if case .success(let matches) = result
		{
			XCTAssertTrue(matches.contains("dog"))
			XCTAssertTrue(matches.contains("cat"))
		}
		else
		{
			XCTAssert(false)
		}

		// Remove 'dog' and make sure list represents it correctly
		XCTAssertTrue(service.delete(password: password1).status())
		let result2 = service.accounts()
		if case .success(let matches) = result2
		{
			XCTAssertFalse(matches.contains("dog"))
			XCTAssertTrue(matches.contains("cat"))
		}
		else
		{
			XCTAssert(false)
		}

		// Remove 'cat'. As we have no passwords stored in the service, this will fail
		XCTAssertTrue(service.delete(password: password2).status())
		let result3 = service.accounts()

		if case .failure(let error) = result3
		{
			XCTAssertEqual(DSFSimpleKeychain.Status.notFound, error)
		}
		else
		{
			XCTAssert(false)
		}
	}

	func testCreateAndAccess()
	{
		let service = DSFSimpleKeychain.Service("SimpleKeychainPassword")

		let password = DSFSimpleKeychain.Service.GenericPassword(account: "dog",
																 password: "securepassword")
		let status = service.add(password: password)
		guard case .success = status else
		{
			XCTAssert(false)
			return
		}

		let result = service.retrieve(accountNamed: "dog")
		if case .success(let account) = result
		{
			XCTAssertTrue(account.valid())
			XCTAssertEqual(account.account, "dog")
			XCTAssertEqual(account.password, "securepassword")
		}
		else
		{
			XCTAssert(false, "Unable to retrieve simple password item")
		}

		XCTAssertTrue(service.delete(password: password).status())
	}
}
