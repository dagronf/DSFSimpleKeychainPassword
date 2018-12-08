//
//  DSFSimpleKeychain.swift
//  SimpleKeychainPassword
//
//  Created by Darren Ford on 8/12/18.
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

import Foundation

/// Simple conversion from OSStatus (returned from keychain funcs) to our own internal type
fileprivate extension OSStatus
{
	fileprivate func asStatus() -> DSFSimpleKeychain.Status
	{
		switch self
		{
		case errSecSuccess:
			return DSFSimpleKeychain.Status.success
		case errSecUserCanceled:
			return DSFSimpleKeychain.Status.cancelled
		case errSecItemNotFound:
			return DSFSimpleKeychain.Status.notFound
		default:
			return DSFSimpleKeychain.Status.notAuthorized
		}
	}
}

class DSFSimpleKeychain: NSObject
{
	enum Result<Value, Error>
	{
		case success(Value)
		case failure(Error)
	}

	enum Status
	{
		/// The task was successful
		case success
		/// The caller cancelled the requested task
		case cancelled
		/// The caller wasn't authorized to perform the requested task
		case notAuthorized
		/// Password was not found
		case notFound
		/// Unknown error
		case genericError
		/// User didn't provide a password
		case missingPassword

		/// Returns true if the status is 'success', false otherwise
		func status() -> Bool
		{
			return self == .success
		}
	}

	/// Structure representing a keychain 'service'
	struct Service
	{
		let name: String
		init(_ name: String)
		{
			self.name = name
		}
	}
}

extension DSFSimpleKeychain.Service
{
	/// Represents a generic password object.
	class GenericPassword
	{
		let account: String
		let password: String
		init(account: String, password: String = "")
		{
			self.account = account
			self.password = password
		}

		/// Returns true if both the account and password are not empty
		func valid() -> Bool
		{
			return self.account != "" && self.password != ""
		}
	}

	typealias GenericPasswordResult = DSFSimpleKeychain.Result<GenericPassword, DSFSimpleKeychain.Status>

	/// Adds a new password account to the service
	///
	/// - Parameters:
	///   - account: The name of the account
	///   - password: The password for the account
	/// - Returns: Result object containing the created password, or error status
	public func add(accountNamed account: String, password: String) -> GenericPasswordResult
	{
		guard !account.isEmpty,
			!password.isEmpty else
		{
			// Need to have both account and password defined in the password object
			return DSFSimpleKeychain.Result.failure(DSFSimpleKeychain.Status.missingPassword)
		}

		let attributes: [String: Any] = [
			kSecClass as String : kSecClassGenericPassword,
			kSecAttrAccount as String: account,
			kSecAttrService as String: self.name,
			kSecValueData as String: password
		]

		var result: CFTypeRef?
		let status = SecItemAdd(attributes as CFDictionary, &result).asStatus()
		if status == DSFSimpleKeychain.Status.success
		{
			return DSFSimpleKeychain.Result.success(GenericPassword(account: account, password: password))
		}
		return DSFSimpleKeychain.Result.failure(status)
	}

	/// Adds a new password account to the service
	///
	/// - Parameter password: The password object to add
	/// - Returns: Result object containing the created password, or error status
	public func add(password: GenericPassword) -> GenericPasswordResult
	{
		return add(accountNamed: password.account, password: password.password)
	}

	/// Deletes the specified password from the service
	///
	/// - Parameters:
	///   - password: The password to delete
	/// - Returns: Status code
	public func delete(password: GenericPassword) -> DSFSimpleKeychain.Status
	{
		let attributes: [String: Any] = [
			kSecClass as String : kSecClassGenericPassword,
			kSecAttrAccount as String: password.account,
			kSecAttrService as String: self.name
		]

		return SecItemDelete(attributes as CFDictionary).asStatus()
	}

	/// Deletes the specified named account from the service
	///
	/// - Parameter account: The name of the account to delete within the service
	/// - Returns: Status code
	public func delete(accountNamed: String) -> DSFSimpleKeychain.Status
	{
		let attributes: [String: Any] = [
			kSecClass as String : kSecClassGenericPassword,
			kSecAttrAccount as String: accountNamed,
			kSecAttrService as String: self.name
		]

		return SecItemDelete(attributes as CFDictionary).asStatus()
	}

	/// Returns a list of account names that are associated with the service
	///
	/// - Returns: An array of account names contained within the service, or error
	public func accounts() -> DSFSimpleKeychain.Result<[String], DSFSimpleKeychain.Status>
	{
		let query: [String: Any] = [
			kSecClass as String : kSecClassGenericPassword,
			kSecAttrService as String: self.name,
			kSecReturnAttributes as String: kCFBooleanTrue,
			kSecMatchLimit as String: kSecMatchLimitAll
		]

		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result).asStatus()
		guard status == DSFSimpleKeychain.Status.success else
		{
			return DSFSimpleKeychain.Result.failure(status)
		}

		var matches: [String] = []
		if let securityResult = result as? [[String: Any?]]
		{
			for match in securityResult
			{
				if let item = match[kSecAttrAccount as String] as? String
				{
					matches.append(item)
				}
			}
		}

		return DSFSimpleKeychain.Result.success(matches)
	}


	/// Returns the account information, including password, from the specified service and account
	///
	/// - Parameters:
	///   - name: The name of the account
	///   - service: The name of the service
	/// - Returns: Service object containing password, or error
	public func retrieve(accountNamed: String) -> GenericPasswordResult
	{
		let attributes: [String: Any] = [
			kSecClass as String : kSecClassGenericPassword,
			kSecAttrAccount as String: accountNamed,
			kSecAttrService as String: self.name,
			kSecMatchLimit as String: kSecMatchLimitOne as String,
			kSecReturnAttributes as String: true,
			kSecReturnData as String: true
		]

		var result: CFTypeRef?
		let status = SecItemCopyMatching(attributes as CFDictionary, &result).asStatus()
		guard status == DSFSimpleKeychain.Status.success else
		{
			return DSFSimpleKeychain.Result.failure(status)
		}

		guard let securityResult = result as? [String: Any?] else
		{
			return DSFSimpleKeychain.Result.failure(DSFSimpleKeychain.Status.genericError)
		}

		guard let account = securityResult[kSecAttrAccount as String] as? String,
			let passwordData = securityResult[kSecValueData as String] as? Data,
			let password = String(data: passwordData, encoding: String.Encoding.utf8) else
		{
			return DSFSimpleKeychain.Result.failure(DSFSimpleKeychain.Status.genericError)
		}

		let accountData = GenericPassword.init(account: account, password: password)
		return DSFSimpleKeychain.Result.success(accountData)
	}
}
