
/// @param {Struct.AstExpression} value
/// @param {Struct.AstStatement} block
function AstWhile(condition, block) : AstStatement(AstStatementType.While) constructor
{
	self.condition = condition;
	self.block = block;
	
	static toString = function()
	{
		return $"while {self.condition} {self.block}";
	}
}
