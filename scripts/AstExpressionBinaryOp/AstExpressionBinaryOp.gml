
/// @param {Enum.BinaryOp} op
/// @param {Struct.AstExpression} lhs
/// @param {Struct.AstExpression} rhs
function AstExpressionBinaryOp(op, lhs, rhs) : AstExpression(AstExpressionType.BinaryOp) constructor
{
	self.op = op;
	self.lhs = lhs;
	self.rhs = rhs;
	
	static toString = function()
	{
		return $"({self.lhs} {binaryOpSymbolOf(self.op)} {self.rhs})";
	}
}

enum BinaryOp
{
	Add,
	Subtract,
	Multiply,
	Divide,
}

/// @param {Enum.BinaryOp} op
function binaryOpNameOf(op)
{
	static names = [
		"Add",
		"Subtract",
		"Multiply",
		"Divide",
	];
	
	return names[op];
}

/// @param {Enum.BinaryOp} op
function binaryOpSymbolOf(op)
{
	static symbols = [
		"+",
		"-",
		"*",
		"/",
	];
	
	return symbols[op];
}

/// @param {Enum.BinaryOp} op
function binaryOpBindingPowerOf(op)
{
	static bindingPower = [
		1,
		1,
		2,
		2,
	];
	
	return bindingPower[op];
}

/// @param {Enum.TokenType|Struct.Token} token
function binaryOpFromToken(token)
{
	if (is_struct(token))
	{
		token = token.type;
	}
	
	switch (token)
	{
		case TokenType.Plus: return BinaryOp.Add;
		case TokenType.Minus: return BinaryOp.Subtract;
		case TokenType.Multiply: return BinaryOp.Multiply;
		case TokenType.Divide: return BinaryOp.Divide;
	}
	
	return undefined;
}
