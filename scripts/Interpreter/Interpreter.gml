
/// @param {Struct.AstStatement} ast
function Interpreter(ast) constructor
{
	self.ast = ast;
	
	self.globalScope = new InterpreterScope(undefined, undefined,
		{
			string,
			real,
			int64,
			is_string,
			is_real,
			is_numeric,
			is_int32,
			is_int64,
			
			method: function(selfScope, target)
			{
				if (!is_callable(target))
				{
					throw $"method() :: expecting a callable function, got a {typeof(target)} ({target})";
				}
				
				var targetSelfStruct = method_get_self(target);
				
				if (!struct_exists(targetSelfStruct, "thisInterpreter"))
				{
					return method(selfScope, target);
				}
				
				var methodStruct = variable_clone(targetSelfStruct);
				methodStruct.selfScope = selfScope;
				
				return method(methodStruct, target);
			},
			
			global: {}
		}
	);
	
	self.scope = self.globalScope;
	
	self.declareVariable("self", self.getVariable("global"));
	self.declareVariable("other", self.getVariable("global"));
	
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
					return self.executeBlock(statement);
				
				case AstStatementType.FunctionCall:
					self.evaluateFunctionCall(statement.call);
					return undefined;
				
				case AstStatementType.With:
					return self.executeWithStatement(statement);
				
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
						var result = undefined;
						var err = undefined;
						
						try
						{
							result = self.executeStatement(statement.block);
						}
						catch (_err)
						{
							err = _err;
						}
						
						if (result != undefined)
						{
							return result;
						}
						
						if (err != undefined)
						{
							if (is_instanceof(err, RuntimeBreakException))
							{
								if (err.shouldContinue)
								{
									continue;
								}
								else
								{
									break;
								}
							}
							
							throw err;
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
				
				case AstStatementType.Throw:
					throw new RuntimeThrownException(self.evaluateExpression(statement.value));
				
				case AstStatementType.Break:
					throw new RuntimeBreakException(false);
				
				case AstStatementType.Continue:
					throw new RuntimeBreakException(true);
				
				case AstStatementType.Try:
					var result = undefined;
				
					// Error to be thrown after finally {}, if one occurred.
					var postponedError = undefined;
				
					try
					{
						result = self.executeStatement(statement.tryBlock);
					}
					catch (caughtError)
					{
						postponedError = caughtError;
					}
				
					// Handle errors that were created within the confines of the runtime (e.g. throw <expr>).
					if ((statement.catchBlock != undefined) && is_instanceof(postponedError, RuntimeThrownException))
					{
						self.pushScope(self.scope);
						
						self.declareVariable(statement.catchBlock.errorVarName, postponedError.value);
						postponedError = undefined;
						
						try
						{
							result = self.executeStatement(statement.catchBlock.body);
						}
						catch (errorInCatch)
						{
							postponedError = errorInCatch;
						}
						finally
						{
							self.popScope();
						}
					}
				
					if (statement.finallyBlock != undefined)
					{
						result = self.executeStatement(statement.finallyBlock) ?? result;
					}
				
					if (postponedError != undefined)
					{
						throw postponedError;
					}
				
					return result;
				
				default:
					throw $"Unhandled statement type for statement {statement}";
			}
		}
		catch (_err)
		{
			if (is_instanceof(_err, RuntimeException))
			{
				throw _err;
			}
			
			throw $"{_err}\n\tin statement: {statement}";
		}
	}
	
	/// @param {Struct.AstBlock} block
	static executeBlock = function(block)
	{
		// Execute each statement.
		var result = undefined;
		
		for (var i = 0; i < array_length(block.statements); i ++)
		{
			result = self.executeStatement(block.statements[i]);
			
			if (!is_undefined(result))
			{
				// Statement returned a value - it was `return`!
				break;
			}
		}
		
		// If non-undefined, return was hit - we're done.
		return result;
	}
	
	/// @param {Struct.AstWith} withStatement
	static executeWithStatement = function(withStatement)
	{
		var otherScope = self.getVariable("self");
		var selfScope = self.evaluateExpression(withStatement.selfScopeExpr);
		
		self.pushScope(self.scope);
		
		self.declareVariable("self", selfScope);
		self.declareVariable("other", otherScope);
		
		try
		{
			return self.executeStatement(withStatement.block);
		}
		finally
		{
			self.popScope();
		}
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
			
			case AstExpressionType.Ternary:
				if (self.evaluateExpression(expression.condition))
				{
					return self.evaluateExpression(expression.thenExpr);
				}
				else
				{
					return self.evaluateExpression(expression.elseExpr);
				}
			
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
			
			case BinaryOp.NotEqual:
				return lhs != self.evaluateExpression(expr.rhs);
			
			case BinaryOp.GreaterThan:
				return lhs > self.evaluateExpression(expr.rhs);
			
			case BinaryOp.LessThan:
				return lhs < self.evaluateExpression(expr.rhs);
			
			case BinaryOp.GreaterOrEqual:
				return lhs >= self.evaluateExpression(expr.rhs);
			
			case BinaryOp.LessOrEqual:
				return lhs <= self.evaluateExpression(expr.rhs);
			
			default:
				throw $"Unhandled binary operator {binaryOpNameOf(expr.op)} for expression {expr}";
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
				throw $"Unhandled unary operator {unaryOpNameOf(expr.op)} for expression {expr}";
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
		var functionArgs = expr.args;
		var functionBody = expr.body;
		var functionParentScope = self.globalScope;
		
		if (expr.closureType == AstExpressionFunctionClosure.Closure)
		{
			functionParentScope = self.scope;
		}
		
		var thisInterpreter = self;
		var selfScope = self.getVariable("self");
		
		var closure = {
			thisInterpreter,
			functionArgs,
			functionBody,
			functionParentScope,
			selfScope
		};
		
		var func = method(closure, function()
		{
			var thisInterpreter = self.thisInterpreter;
			var functionArgs = self.functionArgs;
			var functionBody = self.functionBody;
			var functionParentScope = self.functionParentScope;
			var selfScope = self.selfScope;
			
			var namedArgumentCount = array_length(functionArgs);
			
			with (thisInterpreter)
			{
				var argumentArray = array_create(argument_count, undefined);
				var argumentCount = max(argument_count, namedArgumentCount);
			
				var otherScope = self.getVariable("self");
				
				self.pushScope(functionParentScope);
				self.declareVariable("self", selfScope);
				self.declareVariable("other", otherScope);
				self.declareVariable("argument", argumentArray);
				self.declareVariable("argument_count", argumentCount);
				
				for (var i = 0; i < argumentCount; i ++)
				{
					var value = argument[i];
					
					if (i < namedArgumentCount)
					{
						var arg = functionArgs[i];
					
						value ??= self.evaluateExpression(arg.defaultValue);
						self.declareVariable(arg.name, value);
					}
					
					self.declareVariable($"argument{i}", value);
					argumentArray[i] = value;
				}
				
				var result = self.executeStatement(functionBody);
				self.popScope();
				
				return result;
			}
		});
		
		if (expr.name != undefined)
		{
			self.setGlobalVariable(expr.name, func);
		}
		
		return func;
	}
	
	/// @param {String} name
	/// @returns {Any}
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
		
		var selfScope = self.getVariable("self");
		
		if (struct_exists(selfScope, name))
		{
			return selfScope[$ name];
		}
		
		throw $"Variable {name} is not declared";
	}
	
	/// @param {String} name
	/// @param {Any} value
	static declareVariable = function(name, value)
	{
		self.scope.variables[$ name] = value;
	}
	
	/// @param {String} name
	/// @param {Any} value
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
	
	/// @param {String} name
	/// @returns {Any}
	static getGlobalVariable = function(name)
	{
		return self.globalScope.variables[$ name];
	}
	
	/// @param {String} name
	/// @param {Any} value
	static setGlobalVariable = function(name, value)
	{
		self.globalScope.variables[$ name] = value;
	}
	
	/// @param {Struct.InterpreterScope} parentScope
	static pushScope = function(parentScope)
	{
		self.scope = new InterpreterScope(self.scope, parentScope, {});
	}
	
	static popScope = function()
	{
		self.scope = self.scope.previousScope;
	}
}

function RuntimeException() constructor
{}

/// @param {Any} value
function RuntimeThrownException(value) : RuntimeException() constructor
{
	self.value = value;
}

/// @param {Bool} shouldContinue
function RuntimeBreakException(shouldContinue) : RuntimeException() constructor
{
	self.shouldContinue = shouldContinue;
}

/// @param {Struct.InterpreterScope} previousScope
/// @param {Struct.InterpreterScope} parentScope
/// @param {Struct} variables
function InterpreterScope(previousScope, parentScope, variables = {}) constructor
{
	self.previousScope = previousScope;
	self.parentScope = parentScope;
	self.variables = variables;
}
