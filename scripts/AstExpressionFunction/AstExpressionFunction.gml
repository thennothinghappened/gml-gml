
/// @param {String} name
/// @param {Array<Struct.AstFunctionArgument>} args
/// @param {Struct.AstStatement} body
/// @param {Enum.AstExpressionFunctionClosure} closureType Whether this function acts as a closure and should capture the variables at its definition site. This is used internally. GML does not support this itself.
function AstExpressionFunction(name, args, body, closureType = AstExpressionFunctionClosure.NotAClosure) : AstExpression(AstExpressionType.Function) constructor
{
	self.args = args;
	self.name = name;
	self.body = body;
	self.closureType = closureType;
	
	enum AstExpressionFunctionClosure
	{
		NotAClosure,
		Closure
	}
	
	static toString = function()
	{
		var out = $"function {self.name}({string_join_ext(", ", self.args)}) {self.body}";
		
		if (self.closureType == AstExpressionFunctionClosure.Closure)
		{
			return $"closure {out}";
		}
		
		return out;
	}
}

/// @param {String} name
/// @param {Any} [defaultValue]
function AstFunctionArgument(name, defaultValue) constructor
{
	self.name = name;
	self.defaultValue = defaultValue;
	
	static toString = function()
	{
		if (self.defaultValue == undefined)
		{
			return self.name;
		}
		
		return $"{self.name} = {self.defaultValue}";
	}
}
