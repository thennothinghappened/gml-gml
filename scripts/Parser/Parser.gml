
/// @param {Struct.Lexer} lexer
function Parser(lexer) constructor
{
	self.lexer = lexer;
	
	/// @ignore
	self.__nextUID = 0;
	
	/// @returns {Struct.AstStatement}
	static parse = function()
	{
		var statements = [];
		
		while (true)
		{
			var statement = self.parseStatement();
			
			if (is_undefined(statement))
			{
				break;
			}
			
			array_push(statements, statement);
		}
		
		return new AstBlock(statements);
	}
	
	/// @returns {Struct.AstStatement|undefined}
	static parseStatement = function(withinBlock = false)
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
					var statement = self.parseStatement(true);
			
					if (is_undefined(statement))
					{
						break;
					}
					
					array_push(statements, statement);
				}
			
				return new AstBlock(statements);
			
			case TokenType.CloseBlock:
				self.lexer.next();
			
				if (withinBlock)
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
					
					case "function":
						return new AstFunctionDeclaration(self.parseFunctionDeclaration());
					
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
					
						var indexVar = new AstExpressionReference($"$$repeat_index_{self.nextUID()}");
					
						return new AstBlock([
							new AstLocalVarDeclaration(indexVar.name, new AstExpressionLiteral(0)),
							new AstWhile(new AstExpressionBinaryOp(BinaryOp.LessThan, indexVar, countExpr), new AstBlock([
								block,
								new AstAssign(indexVar, new AstExpressionBinaryOp(BinaryOp.Add, indexVar, new AstExpressionLiteral(1)))
							]))
						]);
					
					case "var":
						self.lexer.next();
						
						// TODO: support var a = ..., b = ...;
						var name = self.consume(TokenType.Identifier).data;
						var value = undefined;
						
						if (self.accept(TokenType.SingleEquals))
						{
							value = self.parseExpression();
						}
					
						return new AstLocalVarDeclaration(name, value);
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
		
		throw $"unexpected token beginning statement: {expr}, at:\n{self.lexer.formatOffendingArea()}";
	}
	
	/// @returns {Struct.AstExpression}
	static parseExpression = function()
	{
		return self.parseBinaryOp(0);
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
				// Rather than adding *more* AST concepts for this, we're gonna "cheat" by defining the struct literal
				// using an IIFE.
				self.lexer.next();
			
				static createStruct = new AstExpressionLiteral(function()
				{
					var struct = {};
					
					for (var i = 0; i < argument_count; i ++)
					{
						var entry = argument[i];
						struct[$ entry.name] = entry.value;
					}
					
					return struct;
				});
			
				static createStructEntry = new AstExpressionLiteral(function(name, value)
				{
					return { name, value };
				});
			
				var memberDefinitions = [];
				
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
					
					array_push(memberDefinitions, new AstExpressionFunctionCall(createStructEntry, [new AstExpressionLiteral(name.data), value]));
					
					if (!self.accept(TokenType.Comma))
					{
						self.consume(TokenType.CloseBlock);
						break;
					}
				}
			
				return new AstExpressionFunctionCall(createStruct, memberDefinitions);
			
			case TokenType.OpenSquareBracket:
				// Array literal!
				//
				// We'll use the same approach as for struct literals (IIFE) :)
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
