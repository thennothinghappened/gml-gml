
enum AstExpressionType
{
	Literal,
	FunctionCall,
	Function,
	Reference,
	Ternary,
	BinaryOp,
	UnaryOp,
	DotAccess,
	ArrayAccess,
}

/// @param {Enum.AstExpressionType} type
function AstExpression(type) constructor
{
	self.type = type;
}
