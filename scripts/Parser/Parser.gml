
new AstExpressionReference("");

/// @param {Struct.Lexer} lexer
function Parser(lexer) constructor
{
	self.lexer = lexer;
	
	/// @ignore
	self.__nextUID = 0;
	
	enum StatementContext
	{
		Global,
		Block,
		SwitchCase
	}
	
	/// @returns {Struct.AstStatement}
	static parse = function()
	{
		return self.parseBlock(StatementContext.Global);
	}
	
	/// @param {Enum.StatementContext} [context]
	/// @returns {Struct.AstBlock}
	static parseBlock = function(context)
	{
		var statements = [];
		
		while (true)
		{
			var statement = self.parseStatement(context);
			
			if (is_undefined(statement))
			{
				break;
			}
			
			array_push(statements, statement);
		}
		
		return new AstBlock(statements);
	}
	
	/// @param {Enum.StatementContext} [context]
	/// @returns {Struct.AstStatement|undefined}
	static parseStatement = function(context = StatementContext.Global)
	{
		while (self.accept(TokenType.Semicolon))
		{}
	
		var token = self.lexer.peek();
			
		if (token == undefined)
		{
			return undefined;
		}
		
		switch (token.type)
		{
			case TokenType.OpenBlock:
				self.lexer.next();
			
				var statements = [];
			
				while (!self.accept(TokenType.CloseBlock))
				{
					var statement = self.parseStatement(StatementContext.Block);
			
					if (is_undefined(statement))
					{
						self.consume(TokenType.CloseBlock);
						break;
					}
					
					array_push(statements, statement);
				}
			
				return new AstBlock(statements);
			
			case TokenType.CloseBlock:
				if (context != StatementContext.Global)
				{
					return undefined;
				}
				else
				{
					throw $"Unexpected end of block that wasn't opened:\n{self.lexer.formatOffendingArea()}";
				}
			
			case TokenType.Identifier:
				var identName = token.data;
			
				// Is this a keyword?
				switch (identName)
				{
					case "return":
						self.lexer.next();
						return new AstReturn(self.parseExpression());
					
					case "throw":
						self.lexer.next();
						return new AstThrow(self.parseExpression());
					
					case "break":
						self.lexer.next();
						return new AstBreak();
					
					case "continue":
						self.lexer.next();
						return new AstContinue();
					
					case "case":
						if (context == StatementContext.SwitchCase)
						{
							return undefined;
						}
						
						throw $"Unexpected case outside switch:\n{self.lexer.formatOffendingArea()}";
					
					case "default":
						if (context == StatementContext.SwitchCase)
						{
							return undefined;
						}
						
						throw $"Unexpected default case outside switch:\n{self.lexer.formatOffendingArea()}";
					
					case "function":
						return new AstFunctionDeclaration(self.parseFunctionDeclaration());
					
					case "with":
						self.lexer.next();
					
						var selfScopeExpr = self.parseExpression();
						var block = self.parseStatement(context);
					
						return new AstWith(selfScopeExpr, block);
					
					case "if":
						self.lexer.next();
						
						var condition = self.parseExpression();
						var block = self.parseStatement();
						var elseBlock = undefined;
					
						if (self.nextIs(TokenType.Identifier))
						{
							if (self.lexer.peek().data == "else")
							{
								self.lexer.next();
								elseBlock = self.parseStatement();
							}
						}
					
						return new AstIf(condition, block, elseBlock);
					
					case "while":
						self.lexer.next();
						
						var condition = self.parseExpression();
						var block = self.parseStatement();
					
						return new AstWhile(condition, block);
					
					case "repeat":
						// Desugars to a while loop with a secret i variable.
						self.lexer.next();
					
						var countExpr = self.parseExpression();
						var block = self.parseStatement();
					
						var uid = self.nextUID();
						var indexVar = new AstExpressionReference($"$$repeat_index_{uid}");
						var countVar = new AstExpressionReference($"$$repeat_count_{uid}");
					
						return new AstBlock([
							new AstLocalVarDeclaration(indexVar.name, new AstExpressionLiteral(0)),
							new AstLocalVarDeclaration(countVar.name, countExpr),
							new AstWhile(new AstExpressionBinaryOp(BinaryOp.LessThan, indexVar, countVar), new AstBlock([
								block,
								new AstAssign(indexVar, new AstExpressionBinaryOp(BinaryOp.Add, indexVar, new AstExpressionLiteral(1)))
							]))
						]);
					
					case "for":
						// Desugars into a while loop much like the above :D
						self.lexer.next();
						
						self.consume(TokenType.OpenParenthesis);
						
						var doFirst = self.parseStatement();
						self.consume(TokenType.Semicolon);
					
						var condition = self.parseExpression();
						self.consume(TokenType.Semicolon);
					
						var doEachIteration = self.parseStatement();
						self.accept(TokenType.Semicolon);
					
						self.consume(TokenType.CloseParenthesis);
					
						var block = self.parseStatement();
					
						return new AstBlock([
							doFirst,
							new AstWhile(condition, new AstTry(
								block,
								undefined,
								doEachIteration
							))
						]);
					
					case "switch":
						self.lexer.next();
					
						var testExpr = self.parseExpression();
						var testExprVariable = new AstExpressionReference($"$$switch_expr_{self.nextUID()}");
					
						var block = new AstBlock([
							new AstLocalVarDeclaration(testExprVariable.name, testExpr)
						]);
					
						var previousCaseBlock = undefined;
					
						self.consume(TokenType.OpenBlock);
					
						while (!self.accept(TokenType.CloseBlock))
						{
							var caseBlock;
							
							switch (self.consume(TokenType.Identifier).data)
							{
								case "case":
									var caseExpr = self.parseExpression();
									self.consume(TokenType.Colon);
								
									caseBlock = self.parseBlock(StatementContext.SwitchCase);
									array_push(block.statements, new AstIf(new AstExpressionBinaryOp(BinaryOp.Equal, testExprVariable, caseExpr), caseBlock, undefined));
								break;
								
								case "default":
									self.consume(TokenType.Colon);
								
									caseBlock = self.parseBlock(StatementContext.SwitchCase);
									array_push(block.statements, caseBlock);
								break;
							}
							
							if (previousCaseBlock != undefined)
							{
								array_push(previousCaseBlock.statements, caseBlock);
							}
							
							if (is_instanceof(array_last(caseBlock.statements), AstBreak))
							{
								caseBlock = undefined;
							}
							
							previousCaseBlock = caseBlock;
						}
						
						array_push(block.statements, new AstBreak());
						return new AstWhile(new AstExpressionLiteral(true), block);
					
					case "try":
						self.lexer.next();
					
						var tryBlock = self.parseStatement();
						var catchBlock = undefined;
						var finallyBlock = undefined;
						
						if (self.nextIs(TokenType.Identifier) && self.lexer.peek().data == "catch")
						{
							self.lexer.next();
							
							self.consume(TokenType.OpenParenthesis);
							var errorVarName = self.consume(TokenType.Identifier).data;
							self.consume(TokenType.CloseParenthesis);
							
							catchBlock = new AstTry_CatchBlock(errorVarName, self.parseStatement());
						}
					
						if (self.nextIs(TokenType.Identifier) && self.lexer.peek().data == "finally")
						{
							self.lexer.next();
							finallyBlock = self.parseStatement();
						}
					
						return new AstTry(tryBlock, catchBlock, finallyBlock);
					
					case "var":
						self.lexer.next();
					
						var block = new AstBlock([]);
					
						while (true)
						{
							var name = self.consume(TokenType.Identifier).data;
							var value = undefined;
							
							if (self.accept(TokenType.SingleEquals))
							{
								value = self.parseExpression();
							}
							
							array_push(block.statements, new AstLocalVarDeclaration(name, value));
							
							if (!self.accept(TokenType.Comma))
							{
								break;
							}
						}
					
						if (array_length(block.statements) == 1)
						{
							return block.statements[0];
						}
					
						return block;
				}
		}
		
		// Might be an expression that's also a valid statement.
		var expr = self.parseUnaryOperand();
		
		switch (expr.type)
		{
			case AstExpressionType.FunctionCall:
				return new AstFunctionCall(expr);
		}
		
		if (self.accept(TokenType.SingleEquals))
		{
			return new AstAssign(expr, self.parseExpression());
		}
		
		// Might be +=, -=, etc.
		var op = binaryOpFromToken(self.lexer.peek());
		
		if (op != undefined)
		{
			self.lexer.next();
			self.consume(TokenType.SingleEquals);
			
			return new AstAssign(expr, new AstExpressionBinaryOp(op, expr, self.parseExpression()));
		}
		
		throw $"unexpected token beginning statement: {expr}, at:\n{self.lexer.formatOffendingArea()}";
	}
	
	/// @returns {Struct.AstExpression}
	static parseExpression = function()
	{
		var conditionOrExpr = self.parseBinaryOp(0);
		
		if (!self.accept(TokenType.TernaryConditionSeparator))
		{
			return conditionOrExpr;
		}
		
		var thenExpr = self.parseBinaryOp(0);
		self.consume(TokenType.Colon);
		var elseExpr = self.parseBinaryOp(0);
		
		return new AstExpressionTernary(conditionOrExpr, thenExpr, elseExpr);
	}
	
	/// @param {Real} bindingPower
	/// @returns {Struct.AstExpression}
	static parseBinaryOp = function(bindingPower)
	{
		var lhs = self.parseUnaryOp(0);
		
		while (true)
		{
			var op = binaryOpFromToken(self.lexer.peek());
			
			if (is_undefined(op))
			{
				break;
			}
			
			var innerBindingPower = binaryOpBindingPowerOf(op);
			
			if (innerBindingPower < bindingPower)
			{
				break;
			}
			
			self.lexer.next();
			lhs = new AstExpressionBinaryOp(op, lhs, self.parseUnaryOp(0));
		}
		
		return lhs;
	}
	
	/// @param {Real} bindingPower
	/// @returns {Struct.AstExpression}
	static parseUnaryOp = function(bindingPower)
	{
		var token = self.lexer.peek();
		var op = unaryOpFromToken(token);
		
		if (is_undefined(op))
		{
			return self.parseUnaryOperand();
		}
		
		self.lexer.next();
		return new AstExpressionUnaryOp(op, self.parseUnaryOp(bindingPower + 1));
	}
	
	/// @returns {Struct.AstExpression}
	static parseUnaryOperand = function()
	{
		var expr = self.parseTerminalExpression();
		
		while (true)
		{
			if (self.accept(TokenType.OpenParenthesis))
			{
				var args = self.parseCallArgs();
				self.consume(TokenType.CloseParenthesis);
				
				expr = new AstExpressionFunctionCall(expr, args);
			}
			else if (self.accept(TokenType.Period))
			{
				var memberName = self.consume(TokenType.Identifier);
				expr = new AstExpressionDotAccess(expr, new AstExpressionLiteral(memberName.data));
			}
			else if (self.accept(TokenType.OpenStructMemberAccess))
			{
				var memberNameExpr = self.parseExpression();
				self.consume(TokenType.CloseSquareBracket);
				
				expr = new AstExpressionDotAccess(expr, memberNameExpr);
			}
			else if (self.accept(TokenType.OpenSquareBracket))
			{
				var indexExpr = self.parseExpression();
				self.consume(TokenType.CloseSquareBracket);
			
				expr = new AstExpressionArrayAccess(expr, indexExpr);
			}
			else
			{
				break;
			}
		}
		
		return expr;
	}
	
	/// @returns {Struct.AstExpression}
	static parseTerminalExpression = function()
	{
		static exprUndefined = new AstExpressionLiteral(undefined);
		
		var token = self.lexer.peek();
		
		switch (token.type)
		{
			case TokenType.String:
				self.lexer.next();
				return new AstExpressionLiteral(token.data);
			
			case TokenType.Number:
				self.lexer.next();
				return new AstExpressionLiteral(token.data);
			
			case TokenType.OpenParenthesis:
				self.lexer.next();
				var innerExpr = self.parseExpression();
				self.consume(TokenType.CloseParenthesis);
			
				return innerExpr;
			
			case TokenType.Identifier:
				var identName = token.data;
			
				switch (identName)
				{
					case "function":
						return self.parseFunctionDeclaration();
					
					case "undefined":
						self.lexer.next();
						return exprUndefined;
					
					case "true":
						self.lexer.next();
						return new AstExpressionLiteral(true);
					
					case "false":
						self.lexer.next();
						return new AstExpressionLiteral(false);
				}
			
				self.lexer.next();
				return new AstExpressionReference(identName);
			
			case TokenType.OpenBlock:
				// Struct literal!
				//
				// There's a LOT of cheating going on here, we're basically using a closure (not a thing in GML normally!)
				// so that we can effectively use with() as an expression.
				self.lexer.next();
			
				static createStructLiteral = new AstExpressionLiteral(function()
				{
					return {};
				});
			
				var block = new AstBlock([]);
				
				while (!self.accept(TokenType.CloseBlock))
				{
					var name = self.consume(TokenType.Identifier);
					var value;
					
					if (self.accept(TokenType.Colon))
					{
						value = self.parseExpression();
					}
					else
					{
						value = new AstExpressionReference(name.data);
					}
					
					array_push(block.statements, new AstAssign(
						new AstExpressionDotAccess(AstExpressionReference.SELF, new AstExpressionLiteral(name.data)),
						value
					));
					
					if (!self.accept(TokenType.Comma))
					{
						self.consume(TokenType.CloseBlock);
						break;
					}
				}
				
				// Inline with(struct)!
				return new AstExpressionFunctionCall(new AstExpressionFunction($"$$createStruct_{self.nextUID()}$$",
					[],
					// with ({})
					// {
					new AstWith(new AstExpressionFunctionCall(createStructLiteral, []), new AstBlock([
						// Assign each prop.
						block,
			
						// return self;
						new AstReturn(AstExpressionReference.SELF)
					// }
					])),
					AstExpressionFunctionClosure.Closure
				), []);
			
			case TokenType.OpenSquareBracket:
				// Array literal!
				//
				// We'll use the same approach as struct literals, minus the closure :)
				self.lexer.next();
			
				/// @param {Any} ...
				/// @returns {Array}
				static createArrayLiteral = new AstExpressionLiteral(function() {
					var array = array_create(argument_count);
					
					for (var i = 0; i < argument_count; i ++)
					{
						array[i] = argument[i];
					}
					
					return array;
				});
			
				var entries = [];
			
				while (!self.accept(TokenType.CloseSquareBracket))
				{
					var entry = self.parseExpression();
					array_push(entries, entry);
					
					if (!self.accept(TokenType.Comma))
					{
						self.consume(TokenType.CloseSquareBracket);
						break;
					}
				}
			
				return new AstExpressionFunctionCall(createArrayLiteral, entries);
			
			default:
				self.lexer.next();
				throw $"Unexpected token {token} in expression:\n{self.lexer.formatOffendingArea()}";
		}
	}
	
	/// @returns {Array<Struct.AstExpression>}
	static parseCallArgs = function()
	{
		var args = [];
		var token = self.lexer.peek();
		
		if (is_undefined(token))
		{
			throw "Unexpected EOF in function call";
		}
		
		while (!self.nextIs(TokenType.CloseParenthesis))
		{
			array_push(args, self.parseExpression());
			
			if (!self.accept(TokenType.Comma))
			{
				break;
			}
		}
		
		return args;
	}
	
	/// @returns {Struct.AstExpressionFunction}
	static parseFunctionDeclaration = function()
	{
		if (self.consume(TokenType.Identifier).data != "function")
		{
			throw "Expected function keyword to start a function declaration";
		}
		
		var name = undefined;
		
		if (self.nextIs(TokenType.Identifier))
		{
			name = self.lexer.next().data;
		}
		
		self.consume(TokenType.OpenParenthesis);
		
		var args = [];
		
		while (!self.accept(TokenType.CloseParenthesis))
		{
			var argumentName = self.consume(TokenType.Identifier).data;
			var defaultValue = undefined;
			
			if (self.accept(TokenType.SingleEquals))
			{
				defaultValue = self.parseExpression();
			}
			
			array_push(args, new AstFunctionArgument(argumentName, defaultValue));
			
			if (!self.accept(TokenType.Comma))
			{
				self.consume(TokenType.CloseParenthesis);
				break;
			}
		}
		
		var body = self.parseStatement(true);
		return new AstExpressionFunction(name, args, body);
	}
	
	static consume = function(expected)
	{
		var token = self.lexer.next();
		
		if (token.type != expected)
		{
			var area = self.lexer.formatOffendingArea();
			throw $"Expected token type {tokenNameOf(expected)}, got {token}:\n{area}";
		}
		
		return token;
	}
	
	static accept = function(expected)
	{
		if (self.nextIs(expected))
		{
			self.lexer.next();
			return true;
		}
		
		return false;
	}
	
	static nextIs = function(expected)
	{
		var token = self.lexer.peek();
		
		if (token == undefined)
		{
			return false;
		}
		
		return (token.type == expected);
	}
	
	static nextUID = function()
	{
		return self.__nextUID ++;
	}
}
