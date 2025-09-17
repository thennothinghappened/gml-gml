
/// @param {Struct.AstExpression} target
/// @param {Struct.AstExpression} memberNameExpr
function AstExpressionDotAccess(target, memberNameExpr) : AstExpression(AstExpressionType.DotAccess) constructor
{
	self.target = target;
	self.memberNameExpr = memberNameExpr;
	
	static toString = function()
	{
		if (self.memberNameExpr.type == AstExpressionType.Literal)
		{	
			if (is_string(self.memberNameExpr.value))
			{
				return $"{self.target}.{self.memberNameExpr.value}";
			}
		}
		
		return $"{self.target}[$ {self.memberNameExpr}]";
	}
}
