source(output(
		account_id as short,
		customer_id as short,
		account_type as string,
		balance as double
	),
	useSchema: false,
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: true,
	purgeFiles: true,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Bronze_Layer/accounts',
	fileName: 'accounts.csv',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true) ~> Accounts
source(output(
		customer_id as integer,
		first_name as string,
		last_name as string,
		address as string,
		city as string,
		state as string,
		zip as string
	),
	useSchema: false,
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: true,
	purgeFiles: true,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Bronze_Layer/customers',
	fileName: 'customers.csv',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true) ~> Customers
source(output(
		payment_id as short,
		loan_id as short,
		payment_date as date,
		payment_amount as double
	),
	useSchema: false,
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: true,
	purgeFiles: true,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Bronze_Layer/loan_payments',
	fileName: 'loan_payments.csv',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true) ~> LoanPayments
source(output(
		loan_id as short,
		customer_id as short,
		loan_amount as double,
		interest_rate as double,
		loan_term as short
	),
	useSchema: false,
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: true,
	purgeFiles: true,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Bronze_Layer/loans',
	fileName: 'loans.csv',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true) ~> Loans
source(output(
		transaction_id as short,
		account_id as short,
		transaction_date as date,
		transaction_amount as double,
		transaction_type as string
	),
	useSchema: false,
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: true,
	purgeFiles: true,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Bronze_Layer/transactions',
	fileName: 'transactions.csv',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true) ~> Transactions
removeEmptyRecords1 aggregate(groupBy(account_id,
		customer_id,
		account_type,
		balance),
	count = count(account_id)) ~> removeDuplicates1
removeDuplicates1 select(mapColumn(
		AccountID = account_id,
		CustomerID = customer_id,
		AccountType = account_type,
		Balance = balance
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> renameColumns1
removeEmptyRecords2 aggregate(groupBy(customer_id,
		first_name,
		last_name,
		address,
		city,
		state,
		zip),
	count = count(customer_id)) ~> removeDuplicates2
removeDuplicates2 select(mapColumn(
		CustomerID = customer_id,
		FirstName = first_name,
		LastName = last_name,
		Address = address,
		City = city,
		State = state,
		Zip = zip
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> renameColumns2
renameColumns2 derive(CustomerID = iif(isNull(CustomerID), -1, CustomerID),
		FirstName = iif(isNull(trim(FirstName)), "Unknown", FirstName),
		LastName = iif(isNull(trim(LastName)), "Unknown", LastName),
		Address = iif(isNull(trim(Address)), "Unknown", Address),
		City = iif(isNull(trim(City)), "Unknown", City),
		State = iif(isNull(trim(State)), "Unknown", State),
		Zip = iif(isNull(trim(Zip)), "Unknown", Zip)) ~> replaceNullValues2
renameColumns1 derive(AccountType = iif(isNull(trim(AccountType)), 'N/A', AccountType),
		Balance = iif( (isNull(Balance) || Balance<0), 0.0, toFloat(Balance))) ~> replaceNullValues1
LoanPayments filter(!((isNull(payment_id) && isNull(loan_id) && isNull(payment_date) && isNull(payment_amount))) || (! (isNull(payment_id) && isNull(loan_id)))) ~> removeEmptyRecords3
removeEmptyRecords3 aggregate(groupBy(payment_id,
		loan_id,
		payment_date,
		payment_amount),
	count = count(payment_id)) ~> removeDuplicates3
removeDuplicates3 select(mapColumn(
		PaymentID = payment_id,
		LoanID = loan_id,
		PaymentDate = payment_date,
		PaymentAmount = payment_amount
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> renameColumns3
renameColumns3 derive(PaymentDate = iif(isNull(PaymentDate), toDate('1900-01-01'), PaymentDate),
		PaymentAmount = iif(isNull(PaymentAmount), 0.0 , toFloat(PaymentAmount))) ~> replaceNullValues3
Loans filter(!((isNull(loan_id) && isNull(customer_id) && isNull(loan_amount) && isNull(interest_rate) && isNull(loan_term))) || (! (isNull(loan_id) && isNull(customer_id)))) ~> removeEmptyRecords4
removeEmptyRecords4 aggregate(groupBy(loan_id,
		customer_id,
		loan_amount,
		interest_rate,
		loan_term),
	count = count(loan_id)) ~> removeDuplicates4
removeDuplicates4 select(mapColumn(
		LoanID = loan_id,
		CustomerID = customer_id,
		LoanAmount = loan_amount,
		InterestRate = interest_rate,
		LoanTerm = loan_term
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> renameColumns4
renameColumns4 derive(LoanAmount = iif(isNull(LoanAmount), 0.0, toFloat(LoanAmount)),
		InterestRate = iif(isNull(InterestRate), 0.0, toFloat(InterestRate)),
		LoanTerm = iif(isNull(LoanTerm), 0, toInteger(LoanTerm))) ~> derivedColumn4
Transactions filter(!((isNull(transaction_id) && isNull(account_id) && isNull(transaction_date) && isNull(transaction_amount) && isNull(trim(transaction_type)))) || (! (isNull(transaction_id) && isNull(account_id)))) ~> removeEmptyRecords5
removeEmptyRecords5 aggregate(groupBy(transaction_id,
		account_id,
		transaction_date,
		transaction_amount,
		transaction_type),
	count = count(transaction_id)) ~> removeDuplicates5
removeDuplicates5 select(mapColumn(
		TransactionID = transaction_id,
		AccountID = account_id,
		TransactionDate = transaction_date,
		TransactionAmount = transaction_amount,
		TransactionType = transaction_type
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> renameColumns5
renameColumns5 derive(TransactionDate = iif(isNull(TransactionDate), toDate('1900-01-01'), TransactionDate),
		TransactionAmount = iif(isNull(TransactionAmount), 0.0, toFloat(TransactionAmount)),
		TransactionType = iif(isNull(trim(TransactionType)), 'N/A', TransactionType)) ~> replaceNullValues5
Customers filter(!(isNull(customer_id) && isNull(first_name) && isNull(last_name) && isNull(address) && isNull(city) && isNull(state) && isNull(zip))) ~> removeEmptyRecords2
Accounts filter(!(isNull(account_id) && isNull(customer_id) && isNull(account_type) && isNull(balance))
||
!(isNull(account_id) && isNull(customer_id))) ~> removeEmptyRecords1
replaceNullValues1 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Silver_Layer/accounts',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	mapColumn(
		AccountID,
		CustomerID,
		AccountType,
		Balance
	)) ~> sinkSilverLayerAccounts
replaceNullValues2 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Silver_Layer/customers',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	mapColumn(
		CustomerID,
		FirstName,
		LastName,
		Address,
		City,
		State,
		Zip
	)) ~> sinkSilverLayerCustomers
replaceNullValues3 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Silver_Layer/loan_payments',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> sinkSilverLayerLoanPayments
derivedColumn4 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Silver_Layer/loans',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> sinkSilverLayerLoans
replaceNullValues5 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'delimited',
	fileSystem: 'mycontainer',
	folderPath: 'Silver_Layer/transactions',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> sinkSilverLayerTransactions