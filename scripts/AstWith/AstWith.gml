
/// @param {Struct.AstExpression} selfScopeExpr
/// @param {Struct.AstStatement} block
function AstWith(selfScopeExpr, block) : AstStatement(AstStatementType.With) constructor
{
	self.selfScopeExpr = selfScopeExpr;
	self.block = block;
	
	static toString = function()
	{
		return $"with {self.selfScopeExpr} {self.block}";
	}
}
