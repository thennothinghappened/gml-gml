
/// @param {Struct.AstExpression} target
/// @param {Struct.AstExpression} value
function AstAssign(target, value) : AstStatement(AstStatementType.Assign) constructor
{
	self.target = target;
	self.value = value;
	
	static toString = function()
	{
		return $"{self.target} = {self.value};";
	}
}
