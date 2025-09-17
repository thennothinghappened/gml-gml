
/// @param {Struct.AstExpressionFunctionCall} call
function AstFunctionCall(call) : AstStatement(AstStatementType.FunctionCall) constructor
{
	self.call = call;
	
	static toString = function()
	{
		return $"{self.call};";
	}
}
