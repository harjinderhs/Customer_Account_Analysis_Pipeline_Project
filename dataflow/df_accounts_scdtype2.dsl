source(output(
		AccountID as short,
		CustomerID as short,
		AccountType as string,
		Balance as double
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
	wildcardPaths:['Silver_Layer/accounts/*.csv']) ~> Accounts
source(output(
		AccountId as integer,
		Hashkey as long
	),
	allowSchemaDrift: true,
	validateSchema: false,
	format: 'query',
	store: 'sqlserver',
	query: 'Select AccountId, Hashkey from dbo.accounts where isActive=1',
	isolationLevel: 'READ_UNCOMMITTED') ~> Target
Accounts select(mapColumn(
		each(match(1==1),
			concat('src_',$$) = $$)
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> RenameColumns
RenameColumns derive(src_Hashkey = crc32(concat(toString(src_AccountID), toString(src_CustomerID), src_AccountType, toString(src_Balance)))) ~> GenerateHashkey
GenerateHashkey, Target lookup(src_AccountID == AccountId,
	multiple: false,
	pickup: 'any',
	broadcast: 'auto')~> JoinDataWithTarget
JoinDataWithTarget split(isNull(AccountId),
	src_AccountID==AccountId && src_Hashkey!=Hashkey,
	disjoint: false) ~> SplitData@(Insert, Update)
AppendTargetData derive(src_CreatedBy = 'Gold-Dataflow',
		src_CreatedDate = currentTimestamp(),
		src_UpdatedBy = 'Gold-Dataflow',
		src_UpdatedDate = currentTimestamp(),
		src_isActive = 1) ~> InsertAuditColumns
SplitData@Update derive(src_UpdatedBy = 'Gold-Dataflow-Updated',
		src_UpdatedDate = currentTimestamp(),
		src_isActive = 0) ~> UpdateAuditColumns
UpdateAuditColumns alterRow(updateIf(1==1)) ~> DataUpdatePermission
SplitData@Insert, SplitData@Update union(byName: true)~> AppendTargetData
InsertAuditColumns sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		AccountId as integer,
		CustomerId as integer,
		AccountType as string,
		Balance as decimal(10,2),
		CreatedBy as string,
		CreatedDate as timestamp,
		UpdatedBy as string,
		UpdatedDate as timestamp,
		Hashkey as long,
		isActive as integer
	),
	format: 'table',
	store: 'sqlserver',
	schemaName: 'dbo',
	tableName: 'accounts',
	insertable: true,
	updateable: false,
	deletable: false,
	upsertable: false,
	stagingSchemaName: '',
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError',
	mapColumn(
		AccountId = src_AccountID,
		CustomerId = src_CustomerID,
		AccountType = src_AccountType,
		Balance = src_Balance,
		CreatedBy = src_CreatedBy,
		CreatedDate = src_CreatedDate,
		UpdatedBy = src_UpdatedBy,
		UpdatedDate = src_UpdatedDate,
		Hashkey = src_Hashkey,
		isActive = src_isActive
	)) ~> AzureSQLDBInsert
DataUpdatePermission sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		AccountId as integer,
		CustomerId as integer,
		AccountType as string,
		Balance as decimal(10,2),
		CreatedBy as string,
		CreatedDate as timestamp,
		UpdatedBy as string,
		UpdatedDate as timestamp,
		Hashkey as long,
		isActive as integer
	),
	format: 'table',
	store: 'sqlserver',
	schemaName: 'dbo',
	tableName: 'accounts',
	insertable: false,
	updateable: true,
	deletable: false,
	upsertable: false,
	keys:['AccountId','Hashkey'],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError',
	mapColumn(
		AccountId,
		UpdatedBy = src_UpdatedBy,
		UpdatedDate = src_UpdatedDate,
		Hashkey,
		isActive = src_isActive
	)) ~> AzureSQLDBUpdate