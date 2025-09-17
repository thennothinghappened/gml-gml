
enum AstExpressionType
{
	Literal,
	FunctionCall,
	Function,
	Reference,
	BinaryOp,
	UnaryOp,
	DotAccess,
	ArrayAccess
}

/// @param {Enum.AstExpressionType} type
function AstExpression(type) constructor
{
	self.type = type;
}
