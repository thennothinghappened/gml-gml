
/// @param {Struct.AstStatement} ast
function Interpreter(ast) constructor
{
	self.ast = ast;
	
	self.globalScope = {};
	self.scope = self.globalScope;
	
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
			
			case AstStatementType.Assign:
				self.setVariable(statement.name, self.evaluateExpression(statement.value));
				return undefined;
			
			case AstStatementType.DeclareFunction:
				self.evaluateFunctionDefinition(statement.func);
				return undefined;
			
			case AstStatementType.Return:
				return self.evaluateExpression(statement.value);
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
		switch (expr.op)
		{
			case BinaryOp.Add:
				return self.evaluateExpression(expr.lhs) + self.evaluateExpression(expr.rhs);
			
			case BinaryOp.Subtract:
				return self.evaluateExpression(expr.lhs) - self.evaluateExpression(expr.rhs);
			
			case BinaryOp.Multiply:
				return self.evaluateExpression(expr.lhs) * self.evaluateExpression(expr.rhs);
			
			case BinaryOp.Divide:
				return self.evaluateExpression(expr.lhs) / self.evaluateExpression(expr.rhs);
			
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
		var closure = { _self: _self, expr };
		
		var func = method(closure, function()
		{
			var oldScope = _self.scope;
			_self.scope = {};
			static_set(_self.scope, _self.globalScope);
			
			for (var i = 0; i < array_length(expr.args); i ++)
			{
				var arg = expr.args[i];
				var value = argument[i] ?? arg.defaultValue;
				
				_self.scope[$ arg.name] = value;
			}
			
			var result = _self.executeStatement(expr.body);
			_self.scope = oldScope;
			
			return result;
		});
		
		if (expr.name != undefined)
		{
			self.setGlobalVariable(expr.name, func);
		}
		
		return func;
	}
	
	static getVariable = function(name)
	{
		return self.scope[$ name];
	}
	
	static declareVariable = function(name, value)
	{
		self.scope[$ name] = value;
	}
	
	static setVariable = function(name, value)
	{
		var scope = self.scope;
		
		while (is_struct(scope))
		{
			if (struct_exists(scope, name))
			{
				scope[$ name] = value;
				return;
			}
			
			scope = static_get(scope);
		}
		
		self.setGlobalVariable(name, value);
	}
	
	static getGlobalVariable = function(name)
	{
		return self.globalScope[$ name];
	}
	
	static setGlobalVariable = function(name, value)
	{
		self.globalScope[$ name] = value;
	}
}
