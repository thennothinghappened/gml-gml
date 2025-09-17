
/// @param {Struct.AstExpression} callTargetExpr
/// @param {Array<Struct.AstExpression>} args
function AstExpressionFunctionCall(callTargetExpr, args) : AstExpression(AstExpressionType.FunctionCall) constructor
{
	self.callTargetExpr = callTargetExpr;
	self.args = args;
	
	static toString = function()
	{
		return $"{self.callTargetExpr}({string_join_ext(", ", self.args)})";
	}
}
