
/// @param {Struct.AstStatement} tryBlock
/// @param {Struct.AstExpressionFunction} catchFunc
/// @param {Struct.AstStatement|undefined} finallyBlock
function AstTry(tryBlock, catchFunc, finallyBlock) : AstStatement(AstStatementType.Try) constructor
{
	self.tryBlock = tryBlock;
	self.catchFunc = catchFunc;
	self.finallyBlock = finallyBlock;
	
	static toString = function()
	{
		var outString = $"try {self.tryBlock}";
		
		if (self.catchFunc != undefined)
		{
			outString += $" catch ({self.catchFunc.args[0].name}) {self.catchFunc.body}";
		}
		
		if (self.finallyBlock != undefined)
		{
			outString += $" finally {self.finallyBlock}";
		}
		
		return outString;
	}
}
