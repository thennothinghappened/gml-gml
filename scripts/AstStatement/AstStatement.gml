
enum AstStatementType
{
	Block,
	FunctionCall,
	LocalVarDeclaration,
	If,
	While,
	Assign,
	DeclareFunction,
	Return,
	Break,
	Continue,
	Try
}

/// @param {Enum.AstStatementType} type
function AstStatement(type) constructor
{
	self.type = type;
}
