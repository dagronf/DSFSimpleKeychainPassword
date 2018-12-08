//
//  DSFSimpleKeychain+UI.swift
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

import Cocoa

extension DSFSimpleKeychain.Service
{
	public func addGenericPassword() -> GenericPasswordResult
	{
		let alert = NSAlert.init()
		alert.addButton(withTitle: "OK")
		alert.addButton(withTitle: "Cancel")
		
		let msg = "Please enter your account and password for '\(self.name)'"
		alert.messageText = msg
		
		let accessoryStack = NSStackView.init(frame: NSRect(x: 0, y: 0, width: 200, height: 50))
		accessoryStack.orientation = .vertical
		
		let accountField = NSTextField.init(frame: NSRect(x: 0, y: 0, width: 200, height: 20))
		accessoryStack.addArrangedSubview(accountField)
		
		let passwordField = NSSecureTextField.init(frame: NSRect(x: 0, y: 0, width: 200, height: 20))
		accessoryStack.addArrangedSubview(passwordField)
		
		alert.accessoryView = accessoryStack
		if alert.runModal() == .alertFirstButtonReturn
		{
			let password = GenericPassword.init(
				account: accountField.stringValue,
				password: passwordField.stringValue)
			return self.add(password: password)
		}
		return DSFSimpleKeychain.Result.failure(DSFSimpleKeychain.Status.cancelled)
	}
}
