source(output(
		LoanID as short,
		CustomerID as short,
		LoanAmount as double,
		InterestRate as double,
		LoanTerm as short
	),
	useSchema: false,
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: true,
	purgeFiles: true,
	format: 'delimited',
	fileSystem: 'mycontainer',
	columnDelimiter: ',',
	escapeChar: '\\',
	quoteChar: '\"',
	columnNamesAsHeader: true,
	wildcardPaths:['Silver_Layer/loans/*.csv']) ~> Loans
source(output(
		LoanId as integer,
		Hashkey as long
	),
	allowSchemaDrift: true,
	validateSchema: false,
	format: 'query',
	store: 'sqlserver',
	query: 'Select LoanId, Hashkey from dbo.loans',
	isolationLevel: 'READ_UNCOMMITTED') ~> Target
Loans select(mapColumn(
		src_LoanID = LoanID,
		src_CustomerID = CustomerID,
		src_LoanAmount = LoanAmount,
		src_InterestRate = InterestRate,
		src_LoanTerm = LoanTerm
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> RenameColumns
RenameColumns derive(src_Hashkey = crc32(concat(toString(src_LoanID), toString(src_CustomerID), toString(src_LoanAmount), toString(src_InterestRate), toString(src_LoanTerm)))) ~> GenerateHashkey
GenerateHashkey, Target lookup(src_LoanID == LoanId,
	multiple: false,
	pickup: 'any',
	broadcast: 'auto')~> JoinDataWithTarget
JoinDataWithTarget split(isNull(LoanId),
	src_LoanID==LoanId && src_Hashkey!=Hashkey,
	disjoint: false) ~> SplitData@(Insert, Update)
SplitData@Insert derive(src_CreatedBy = 'Gold-Dataflow',
		src_CreatedDate = currentTimestamp(),
		src_UpdatedBy = 'Gold-Dataflow',
		src_UpdatedDate = currentTimestamp()) ~> InsertAuditColumns
SplitData@Update derive(src_UpdatedBy = 'Gold-Dataflow-Updated',
		src_UpdatedDate = currentTimestamp()) ~> UpdateAuditColumns
UpdateAuditColumns alterRow(updateIf(1==1)) ~> DataUpdatePermission
InsertAuditColumns sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		LoanId as integer,
		CustomerId as integer,
		LoanAmount as decimal(10,2),
		InterestRate as decimal(5,2),
		LoanTerm as integer,
		CreatedBy as string,
		CreatedDate as timestamp,
		UpdatedBy as string,
		UpdatedDate as timestamp,
		Hashkey as long
	),
	format: 'table',
	store: 'sqlserver',
	schemaName: 'dbo',
	tableName: 'loans',
	insertable: true,
	updateable: false,
	deletable: false,
	upsertable: false,
	stagingSchemaName: '',
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError',
	mapColumn(
		LoanId = src_LoanID,
		CustomerId = src_CustomerID,
		LoanAmount = src_LoanAmount,
		InterestRate = src_InterestRate,
		LoanTerm = src_LoanTerm,
		CreatedBy = src_CreatedBy,
		CreatedDate = src_CreatedDate,
		UpdatedBy = src_UpdatedBy,
		UpdatedDate = src_UpdatedDate,
		Hashkey = src_Hashkey
	)) ~> AzureSQLDBInsert
DataUpdatePermission sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		LoanId as integer,
		CustomerId as integer,
		LoanAmount as decimal(10,2),
		InterestRate as decimal(5,2),
		LoanTerm as integer,
		CreatedBy as string,
		CreatedDate as timestamp,
		UpdatedBy as string,
		UpdatedDate as timestamp,
		Hashkey as long
	),
	format: 'table',
	store: 'sqlserver',
	schemaName: 'dbo',
	tableName: 'loans',
	insertable: false,
	updateable: true,
	deletable: false,
	upsertable: false,
	keys:['LoanId'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError',
	mapColumn(
		LoanId = src_LoanID,
		CustomerId = src_CustomerID,
		LoanAmount = src_LoanAmount,
		InterestRate = src_InterestRate,
		LoanTerm = src_LoanTerm,
		UpdatedBy = src_UpdatedBy,
		UpdatedDate = src_UpdatedDate,
		Hashkey = src_Hashkey
	)) ~> AzureSQLDBUpdate