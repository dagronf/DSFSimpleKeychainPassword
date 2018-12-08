# DSFSimpleKeychain

A simple Swift wrapper around keychain functions for storing and retrieving keychain 'generic passwords'

## Create a keychain password

		let service = DSFSimpleKeychain.Service("My Application Data")
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

### Command line equivalent

		$ security add-generic-password -s "My Application Data" -a "AWSLoginID" -w "<password>"

## List the stored passwords for a service

		let service = DSFSimpleKeychain.Service("My Application Data")
		let allAccounts = service.accounts()
		if case .success(let accounts) = allAccounts
		{
			print("Found accounts: \(accounts)")
		}
		else
		{
			print("Unable to retrieve account information")
		}

## Retrieve a keychain password

		let service = DSFSimpleKeychain.Service("My Application Data")
		let retrieveStatus = service.retrieve(accountNamed: "AWSLoginID")
		guard case .success(let accountInfo) = retrieveStatus else
		{
			print("Unable to retrieve password")
			return
		}
		print("Password is \(accountInfo.password)")

### Command line equivalent
		
		$ security find-generic-password -s "My Application Data" -a "AWSLoginID" -w
		<password>

## Delete a password from the keychain

		let service = DSFSimpleKeychain.Service("My Application Data")
		let deleteResult = service.delete(accountNamed: "AWSLoginID")
		if deleteResult != DSFSimpleKeychain.Status.success
		{
			print("Unable to delete password")
			return
		}

### Command line equivalent

		$ security delete-generic-password -s "My Application Data" -a "AWSLoginID" 
