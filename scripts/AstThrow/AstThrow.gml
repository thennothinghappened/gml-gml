
/// @param {Struct.AstExpression} value
function AstThrow(value) : AstStatement(AstStatementType.Throw) constructor
{
	self.value = value;
	
	static toString = function()
	{
		return $"throw {self.value};";
	}
}
