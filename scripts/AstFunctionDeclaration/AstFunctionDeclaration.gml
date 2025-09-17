
/// @param {Struct.AstExpressionFunction} func
function AstFunctionDeclaration(func) : AstStatement(AstStatementType.DeclareFunction) constructor
{
	self.func = func;
	
	static toString = function()
	{
		return string(self.func);
	}
}
