
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
	Equal,
	NotEqual,
	GreaterThan,
	LessThan,
	GreaterOrEqual,
	LessOrEqual
}

/// @param {Enum.BinaryOp} op
function binaryOpNameOf(op)
{
	static names = [
		"Add",
		"Subtract",
		"Multiply",
		"Divide",
		"Equal",
		"NotEqual",
		"GreaterThan",
		"LessThan",
		"GreaterOrEqual",
		"LessOrEqual",
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
		"==",
		"!=",
		">",
		"<",
		">=",
		"<="
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
		0,
		0,
		0,
		0,
		0,
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
		case TokenType.SingleEquals: return BinaryOp.Equal;
		case TokenType.DoubleEquals: return BinaryOp.Equal;
		case TokenType.NotEqual: return BinaryOp.NotEqual;
		case TokenType.GreaterThan: return BinaryOp.GreaterThan;
		case TokenType.LessThan: return BinaryOp.LessThan;
		case TokenType.GreaterOrEqual: return BinaryOp.GreaterOrEqual;
		case TokenType.LessOrEqual: return BinaryOp.LessOrEqual;
	}
	
	return undefined;
}
