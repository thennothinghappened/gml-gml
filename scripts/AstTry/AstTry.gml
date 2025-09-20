
/// @param {Struct.AstStatement} tryBlock
/// @param {Struct.AstTry_CatchBlock} catchFunc
/// @param {Struct.AstStatement|undefined} finallyBlock
function AstTry(tryBlock, catchBlock, finallyBlock) : AstStatement(AstStatementType.Try) constructor
{
	self.tryBlock = tryBlock;
	self.catchBlock = catchBlock;
	self.finallyBlock = finallyBlock;
	
	static toString = function()
	{
		var outString = $"try {self.tryBlock}";
		
		if (self.catchBlock != undefined)
		{
			outString += $" {self.catchBlock}";
		}
		
		if (self.finallyBlock != undefined)
		{
			outString += $" finally {self.finallyBlock}";
		}
		
		return outString;
	}
}

/// @param {String} errorVarName
/// @param {Struct.AstStatement} body
function AstTry_CatchBlock(errorVarName, body) constructor
{
	self.errorVarName = errorVarName;
	self.body = body;
	
	static toString = function()
	{
		return $"catch ({self.errorVarName}) {self.body}";
	}
}
