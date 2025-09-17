
/// @param {String} name
/// @param {Struct.AstExpression} value
function AstLocalVarDeclaration(name, value) : AstStatement(AstStatementType.LocalVarDeclaration) constructor
{
	self.name = name;
	self.value = value;
	
	static toString = function()
	{
		return $"var {self.name} = {self.value};";
	}
}
