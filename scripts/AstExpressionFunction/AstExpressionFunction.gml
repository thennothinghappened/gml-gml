
/// @param {String|undefined} name
/// @param {Array<Struct.AstFunctionArgument>} args
/// @param {Struct.AstStatement} body
function AstExpressionFunction(name, args, body) : AstExpression(AstExpressionType.Function) constructor
{
	self.args = args;
	self.name = name;
	self.body = body;
	
	static toString = function()
	{
		var argsString = string_join_ext(", ", self.args);
		
		if (self.name == undefined)
		{
			return $"function({argsString}) {self.body}";
		}
		
		return $"function {self.name}({argsString}) {self.body}";
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
