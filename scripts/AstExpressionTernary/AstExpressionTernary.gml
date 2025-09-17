
/// @param {Struct.AstExpression} condition
/// @param {Struct.AstExpression} thenExpr
/// @param {Struct.AstExpression} elseExpr
function AstExpressionTernary(condition, thenExpr, elseExpr) : AstExpression(AstExpressionType.Ternary) constructor
{
	self.condition = condition;
	self.thenExpr = thenExpr;
	self.elseExpr = elseExpr;
	
	static toString = function()
	{
		return $"{self.condition} ? {self.thenExpr} : {self.elseExpr}";
	}
}
