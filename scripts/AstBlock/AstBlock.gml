
/// @param {Array<Struct.AstStatement>} statements
/// @param {Bool} [injectIntoParentScope] Whether this block should be treated as part of the parent. This allows a block to be used as a carrier for a list of statements, which are functionally one statement.
function AstBlock(statements, injectIntoParentScope = false) : AstStatement(AstStatementType.Block) constructor
{
	self.statements = statements;
	self.injectIntoParentScope = injectIntoParentScope;
	
	static toString = function()
	{
		var outString = array_reduce(self.statements, function(prev, current)
		{
			static isAssignment = function(statement)
			{
				return (statement.type == AstStatementType.Assign)
					|| (statement.type == AstStatementType.LocalVarDeclaration);
			};

			var outString = prev.outString + "\n";

			breakable
			{
				if (!struct_exists(prev, "ast"))
				{
					break;
				}
				
				if (string_count("\n", string(current)) == 0)
				{
					if (prev.ast.type == current.type)
					{
						break;
					}
					
					if (isAssignment(prev.ast) == isAssignment(current))
					{
						break;
					}
				}
				
				outString += "\n";
			}

			outString += string(current);

			return {
				ast: current,
				outString
			};
		}, { outString: "" }).outString;
		
		outString = "{" + indent(outString) + "\n}";
		
		if (self.injectIntoParentScope)
		{
			outString = "unscoped " + outString;
		}
		
		return outString;
	}
}
