
/// @param {Enum.UnaryOp} op
/// @param {Struct.AstExpression} expr
function AstExpressionUnaryOp(op, expr) : AstExpression(AstExpressionType.UnaryOp) constructor
{
	self.op = op;
	self.expr = expr;
	
	static toString = function()
	{
		return $"{unaryOpNameOf(self.op)}({self.expr})";
	}
}

enum UnaryOp
{
	Negative,
	Not,
}

/// @param {Enum.UnaryOp} op
function unaryOpNameOf(op)
{
	static names = [
		"Negative",
		"Not",
	];
	
	return names[op];
}

/// @param {Enum.UnaryOp} op
function unaryOpBindingPowerOf(op)
{
	static bindingPower = [
		1,
		1,
	];
	
	return bindingPower[op];
}

/// @param {Enum.TokenType|Struct.Token} token
function unaryOpFromToken(token)
{
	if (is_struct(token))
	{
		token = token.type;
	}
	
	switch (token)
	{
		case TokenType.Minus: return UnaryOp.Negative;
		case TokenType.Not: return UnaryOp.Not;
	}
	
	return undefined;
}
