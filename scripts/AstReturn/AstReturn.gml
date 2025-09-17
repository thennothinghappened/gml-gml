
/// @param {Struct.AstExpression} value
function AstReturn(value) : AstStatement(AstStatementType.Return) constructor
{
	self.value = value;
	
	static toString = function()
	{
		return $"return {self.value};";
	}
}
