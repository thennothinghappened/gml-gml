
function AstExpressionLiteral(value) : AstExpression(AstExpressionType.Literal) constructor
{
	self.value = value;
	
	static toString = function()
	{
		if (is_string(self.value))
		{
			return $"\"{string_replace(string_replace(self.value, "\\", "\\\\"), "\"", "\\\"")}\"";
		}
		
		return string(self.value);
	}
	
	static TRUE = new AstExpressionLiteral(true);
	static FALSE = new AstExpressionLiteral(false);
	static UNDEFINED = new AstExpressionLiteral(undefined);
}
