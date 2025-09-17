
/// @param {Struct.AstExpression} target
/// @param {Struct.AstExpression} indexExpr
function AstExpressionArrayAccess(target, indexExpr) : AstExpression(AstExpressionType.ArrayAccess) constructor
{
	self.target = target;
	self.indexExpr = indexExpr;
	
	static toString = function()
	{
		return $"{self.target}[{self.indexExpr}]";
	}
}
