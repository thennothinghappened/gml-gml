
/// @param {String} name
function AstExpressionReference(name) : AstExpression(AstExpressionType.Reference) constructor
{
	static SELF = new AstExpressionReference("self");
	
	self.name = name;
	
	static toString = function()
	{
		return self.name;
	}
}
