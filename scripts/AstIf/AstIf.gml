
/// @param {Struct.AstExpression} value
/// @param {Struct.AstStatement} block
/// @param {Struct.AstStatement|undefined} elseBlock
function AstIf(condition, block, elseBlock) : AstStatement(AstStatementType.If) constructor
{
	self.condition = condition;
	self.block = block;
	self.elseBlock = elseBlock;
	
	static toString = function()
	{
		var outString = $"if {self.condition} {self.block}";
		
		if (self.elseBlock != undefined)
		{
			outString += $" else {self.elseBlock}";
		}
		
		return outString;
	}
}
