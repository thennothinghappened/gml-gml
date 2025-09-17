
function AstContinue() : AstStatement(AstStatementType.Continue) constructor
{
	static toString = function()
	{
		return "continue;";
	}
}
