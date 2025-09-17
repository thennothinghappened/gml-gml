
/// @param {Struct.AstStatement} ast
function Interpreter(ast) constructor
{
	self.ast = ast;
	
	self.globalScope = { parentScope: undefined, variables: {} };
	
	var parentScope = self.globalScope;
	self.scope = { parentScope, variables: {} };
	
	/// Define a top-level member in the environment. Can be used to expose functions.
	/// 
	/// @param {String} name
	/// @param {Any} value
	static define = function(name, value)
	{
		self.setVariable(name, value);
		return self;
	}
	
	/// Execute the program, and return its result.
	static execute = function()
	{
		show_debug_message($"Executing Program: {self.ast}");
		return self.executeStatement(self.ast);
	}
	
	/// @param {Struct.AstStatement} statement
	static executeStatement = function(statement)
	{
		try
		{
			switch (statement.type)
			{
				case AstStatementType.Block:
					return self.executeBlock(statement.statements);
				
				case AstStatementType.FunctionCall:
					self.evaluateFunctionCall(statement.call);
					return undefined;
				
				case AstStatementType.LocalVarDeclaration:
					self.declareVariable(statement.name, self.evaluateExpression(statement.value));
					return undefined;
				
				case AstStatementType.If:
					if (self.evaluateExpression(statement.condition))
					{
						return self.executeStatement(statement.block);
					}
					else if (statement.elseBlock != undefined)
					{
						return self.executeStatement(statement.elseBlock);
					}
				
					return undefined;
				
				case AstStatementType.While:
					while (self.evaluateExpression(statement.condition))
					{
						var result = self.executeStatement(statement.block);
						
						if (result != undefined)
						{
							return result;
						}
					}
				
					return undefined;
				
				case AstStatementType.Assign:
					self.executeAssign(statement);
					return undefined;
				
				case AstStatementType.DeclareFunction:
					self.evaluateFunctionDefinition(statement.func);
					return undefined;
				
				case AstStatementType.Return:
					return self.evaluateExpression(statement.value);
			}
		}
		catch (err)
		{
			throw $"{err}\n\tin statement: {statement}";
		}
	}
	
	/// @param {Array<Struct.AstStatement>} statements
	static executeBlock = function(statements)
	{
		// Begin a new scope.
		var parentScope = self.scope;
		
		self.scope = {};
		static_set(self.scope, parentScope);
		
		// Execute each statement.
		var result = undefined;
		
		for (var i = 0; i < array_length(statements); i ++)
		{
			result = self.executeStatement(statements[i]);
			
			if (!is_undefined(result))
			{
				// Statement returned a value - it was `return`!
				break;
			}
		}
		
		// Restore the parent scope.
		self.scope = parentScope;
		
		// If non-undefined, return was hit - we're done.
		return result;
	}
	
	/// @param {Struct.AstAssign} statement
	static executeAssign = function(statement)
	{
		var value = self.evaluateExpression(statement.value);
		
		switch (statement.target.type)
		{
			case AstExpressionType.Reference:
				self.setVariable(statement.target.name, value);
			break;

			case AstExpressionType.DotAccess:
				self.evaluateExpression(statement.target.target)[$ self.evaluateExpression(statement.target.memberNameExpr)] = value;
			break;
			
			case AstExpressionType.ArrayAccess:
				self.evaluateExpression(statement.target.target)[self.evaluateExpression(statement.target.indexExpr)] = value;
			break;
			
			default:
				throw $"{statement.target} is not a valid assign target ({statement})";
		}
	}
	
	/// @param {Struct.AstExpression} expression
	static evaluateExpression = function(expression)
	{
		switch (expression.type)
		{
			case AstExpressionType.Literal:
				return self.evaluateLiteral(expression);
			
			case AstExpressionType.FunctionCall:
				return self.evaluateFunctionCall(expression);
			
			case AstExpressionType.Function:
				return self.evaluateFunctionDefinition(expression);
			
			case AstExpressionType.Reference:
				return self.evaluateReference(expression);
			
			case AstExpressionType.BinaryOp:
				return self.evaluateBinaryOp(expression);
			
			case AstExpressionType.UnaryOp:
				return self.evaluateUnaryOp(expression);
			
			case AstExpressionType.DotAccess:
				return self.evaluateExpression(expression.target)[$ self.evaluateExpression(expression.memberNameExpr)];
			
			case AstExpressionType.ArrayAccess:
				return self.evaluateExpression(expression.target)[self.evaluateExpression(expression.indexExpr)];
			
			default:
				throw $"Unhandled expression type for expression {expression}";
		}
	}
	
	/// @param {Struct.AstExpressionLiteral} expr
	static evaluateLiteral = function(expr)
	{
		return expr.value;
	}
	
	/// @param {Struct.AstExpressionReference} expr
	static evaluateReference = function(expr)
	{
		return self.getVariable(expr.name);
	}
	
	/// @param {Struct.AstExpressionBinaryOp} expr
	static evaluateBinaryOp = function(expr)
	{
		// Sneaky tiny optimisation, only eagarly eval lhs (for and/or).
		var lhs = self.evaluateExpression(expr.lhs);
		
		switch (expr.op)
		{
			case BinaryOp.Add:
				return lhs + self.evaluateExpression(expr.rhs);
			
			case BinaryOp.Subtract:
				return lhs - self.evaluateExpression(expr.rhs);
			
			case BinaryOp.Multiply:
				return lhs * self.evaluateExpression(expr.rhs);
			
			case BinaryOp.Divide:
				return lhs / self.evaluateExpression(expr.rhs);
			
			case BinaryOp.Equal:
				return lhs == self.evaluateExpression(expr.rhs);
			
			case BinaryOp.GreaterThan:
				return lhs > self.evaluateExpression(expr.rhs);
			
			case BinaryOp.LessThan:
				return lhs < self.evaluateExpression(expr.rhs);
			
			case BinaryOp.GreaterOrEqual:
				return lhs >= self.evaluateExpression(expr.rhs);
			
			case BinaryOp.LessOrEqual:
				return lhs <= self.evaluateExpression(expr.rhs);
			
			default:
				throw $"Unhandled binary operator {expr.op} for expression {expr}";
		}
	}
	
	/// @param {Struct.AstExpressionUnaryOp} expr
	static evaluateUnaryOp = function(expr)
	{
		switch (expr.op)
		{
			case UnaryOp.Negative:
				return -self.evaluateExpression(expr.expr);
			
			case UnaryOp.Not:
				return !self.evaluateExpression(expr.expr);
			
			default:
				throw $"Unhandled unary operator {expr.op} for expression {expr}";
		}
	}
	
	/// @param {Struct.AstExpressionFunctionCall} expr
	static evaluateFunctionCall = function(expr)
	{
		var callTarget = self.evaluateExpression(expr.callTargetExpr);
		
		if (!is_callable(callTarget))
		{
			throw $"Cannot call non-callable: {expr.callTargetExpr}";
		}
		
		return method_call(callTarget, array_map(expr.args, self.evaluateExpression));
	}
	
	/// @param {Struct.AstExpressionFunction} expr
	static evaluateFunctionDefinition = function(expr)
	{
		var _self = self;
		var closure = { _self, expr };
		
		var func = method(closure, function()
		{
			var expr = self.expr;
			var _self = self._self;
			
			with (_self)
			{
				var oldScope = self.scope;
				self.scope = {};
				static_set(self.scope, self.globalScope);
				
				for (var i = 0; i < array_length(expr.args); i ++)
				{
					var arg = expr.args[i];
					var value = argument[i] ?? self.evaluateExpression(arg.defaultValue);
					
					self.scope[$ arg.name] = value;
				}
				
				var result = self.executeStatement(expr.body);
				self.scope = oldScope;
				
				return result;
			}
		});
		
		if (expr.name != undefined)
		{
			self.setGlobalVariable(expr.name, func);
		}
		
		return func;
	}
	
	static getVariable = function(name)
	{
		var scope = self.scope;
		
		while (!is_undefined(scope))
		{
			if (struct_exists(scope.variables, name))
			{
				return scope.variables[$ name];
			}
			
			scope = scope.parentScope;
		}
		
		throw $"Variable {name} is not declared";
	}
	
	static declareVariable = function(name, value)
	{
		self.scope.variables[$ name] = value;
	}
	
	static setVariable = function(name, value)
	{
		var scope = self.scope;
		
		while (true)
		{
			if (struct_exists(scope.variables, name))
			{
				scope.variables[$ name] = value;
				break;
			}
			
			if (is_undefined(scope.parentScope))
			{
				self.setGlobalVariable(name, value);
				break;
			}
			
			scope = scope.parentScope;
		}
	}
	
	static getGlobalVariable = function(name)
	{
		return self.globalScope.variables[$ name];
	}
	
	static setGlobalVariable = function(name, value)
	{
		self.globalScope.variables[$ name] = value;
	}
}
