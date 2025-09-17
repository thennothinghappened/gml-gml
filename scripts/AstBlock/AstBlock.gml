
/// @param {Array<Struct.AstStatement>} statements
function AstBlock(statements) : AstStatement(AstStatementType.Block) constructor
{
	self.statements = statements;
	
	static toString = function()
	{
		return "{" + indent(array_reduce(self.statements, function(prev, current)
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
		}, { outString: "" }).outString) + "\n}";
	}
}
