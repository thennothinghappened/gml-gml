
/// @param {String} name
function AstExpressionReference(name) : AstExpression(AstExpressionType.Reference) constructor
{
	self.name = name;
	
	static toString = function()
	{
		return self.name;
	}
}
