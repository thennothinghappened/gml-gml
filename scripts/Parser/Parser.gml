
enum AstStatementType
{
	Block,
	FunctionCall,
	LocalVarDeclaration,
	If,
	Assign,
	DeclareFunction,
	Return
}

/// @param {Enum.AstStatementType} type
function AstStatement(type) constructor
{
	self.type = type;
}

#macro breakable repeat (1)

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

/// @param {Struct.AstExpressionFunctionCall} call
function AstFunctionCall(call) : AstStatement(AstStatementType.FunctionCall) constructor
{
	self.call = call;
	
	static toString = function()
	{
		return $"{self.call};";
	}
}

/// @param {String} name
/// @param {Struct.AstExpression} value
function AstLocalVarDeclaration(name, value) : AstStatement(AstStatementType.LocalVarDeclaration) constructor
{
	self.name = name;
	self.value = value;
	
	static toString = function()
	{
		return $"var {self.name} = {self.value};";
	}
}

/// @param {Struct.AstExpression} value
/// @param {Struct.AstStatement} block
/// @param {Struct.AstStatement|undefined} elseBlock
function AstIf(condition, block, elseBlock) : AstStatement(AstStatementType.If) constructor
{
	self.condition = condition;
	self.block = block;
	self.elseBlock = elseBlock;
	
	static toString = function()
	{
		var outString = $"if {self.condition} {self.block}";
		
		if (self.elseBlock != undefined)
		{
			outString += $" else {self.elseBlock}";
		}
		
		return outString;
	}
}

/// @param {Struct.AstExpression} target
/// @param {Struct.AstExpression} value
function AstAssign(target, value) : AstStatement(AstStatementType.Assign) constructor
{
	self.target = target;
	self.value = value;
	
	static toString = function()
	{
		return $"{self.target} = {self.value};";
	}
}

/// @param {Struct.AstExpressionFunction} func
function AstFunctionDeclaration(func) : AstStatement(AstStatementType.DeclareFunction) constructor
{
	self.func = func;
	
	static toString = function()
	{
		return string(self.func);
	}
}

/// @param {Struct.AstExpression} value
function AstReturn(value) : AstStatement(AstStatementType.Return) constructor
{
	self.value = value;
	
	static toString = function()
	{
		return $"return {self.value};";
	}
}

enum AstExpressionType
{
	Literal,
	FunctionCall,
	Function,
	Reference,
	BinaryOp,
	UnaryOp,
	DotAccess,
	ArrayAccess
}

/// @param {Enum.AstExpressionType} type
function AstExpression(type) constructor
{
	self.type = type;
}

function AstExpressionLiteral(value) : AstExpression(AstExpressionType.Literal) constructor
{
	self.value = value;
	
	static toString = function()
	{
		if (is_string(self.value))
		{
			return $"\"{string_replace(string_replace(self.value, "\\", "\\\\"), "\"", "\\\"")}\"";
		}
		
		return string(self.value);
	}
}

/// @param {Struct.AstExpression} callTargetExpr
/// @param {Array<Struct.AstExpression>} args
function AstExpressionFunctionCall(callTargetExpr, args) : AstExpression(AstExpressionType.FunctionCall) constructor
{
	self.callTargetExpr = callTargetExpr;
	self.args = args;
	
	static toString = function()
	{
		return $"{self.callTargetExpr}({string_join_ext(", ", self.args)})";
	}
}

/// @param {String|undefined} name
/// @param {Array<Struct.AstFunctionArgument>} args
/// @param {Struct.AstStatement} body
function AstExpressionFunction(name, args, body) : AstExpression(AstExpressionType.Function) constructor
{
	self.args = args;
	self.name = name;
	self.body = body;
	
	static toString = function()
	{
		var argsString = string_join_ext(", ", self.args);
		
		if (self.name == undefined)
		{
			return $"function({argsString}) {self.body}";
		}
		
		return $"function {self.name}({argsString}) {self.body}";
	}
}

/// @param {Struct.AstExpression} target
/// @param {Struct.AstExpression} memberNameExpr
function AstExpressionDotAccess(target, memberNameExpr) : AstExpression(AstExpressionType.DotAccess) constructor
{
	self.target = target;
	self.memberNameExpr = memberNameExpr;
	
	static toString = function()
	{
		if (self.memberNameExpr.type == AstExpressionType.Literal)
		{	
			if (is_string(self.memberNameExpr.value))
			{
				return $"{self.target}.{self.memberNameExpr.value}";
			}
		}
		
		return $"{self.target}[$ {self.memberNameExpr}]";
	}
}

/// @param {Struct.AstExpression} target
/// @param {Struct.AstExpression} indexExpr
function AstExpressionArrayAccess(target, indexExpr) : AstExpression(AstExpressionType.ArrayAccess) constructor
{
	self.target = target;
	self.indexExpr = indexExpr;
	
	static toString = function()
	{
		return $"{self.target}[{self.indexExpr}]";
	}
}

/// @param {String} name
/// @param {Any} [defaultValue]
function AstFunctionArgument(name, defaultValue) constructor
{
	self.name = name;
	self.defaultValue = defaultValue;
	
	static toString = function()
	{
		if (self.defaultValue == undefined)
		{
			return self.name;
		}
		
		return $"{self.name} = {self.defaultValue}";
	}
}

enum BinaryOp
{
	Add,
	Subtract,
	Multiply,
	Divide,
}

/// @param {Enum.BinaryOp} op
function binaryOpNameOf(op)
{
	static names = [
		"Add",
		"Subtract",
		"Multiply",
		"Divide",
	];
	
	return names[op];
}

/// @param {Enum.BinaryOp} op
function binaryOpSymbolOf(op)
{
	static symbols = [
		"+",
		"-",
		"*",
		"/",
	];
	
	return symbols[op];
}

/// @param {Enum.BinaryOp} op
function binaryOpBindingPowerOf(op)
{
	static bindingPower = [
		1,
		1,
		2,
		2,
	];
	
	return bindingPower[op];
}

/// @param {Enum.TokenType|Struct.Token} token
function binaryOpFromToken(token)
{
	if (is_struct(token))
	{
		token = token.type;
	}
	
	switch (token)
	{
		case TokenType.Plus: return BinaryOp.Add;
		case TokenType.Minus: return BinaryOp.Subtract;
		case TokenType.Multiply: return BinaryOp.Multiply;
		case TokenType.Divide: return BinaryOp.Divide;
	}
	
	return undefined;
}

enum UnaryOp
{
	Negative,
	Not,
}

/// @param {Enum.UnaryOp} op
function unaryOpNameOf(op)
{
	static names = [
		"Negative",
		"Not",
	];
	
	return names[op];
}

/// @param {Enum.UnaryOp} op
function unaryOpBindingPowerOf(op)
{
	static bindingPower = [
		1,
		1,
	];
	
	return bindingPower[op];
}

/// @param {Enum.TokenType|Struct.Token} token
function unaryOpFromToken(token)
{
	if (is_struct(token))
	{
		token = token.type;
	}
	
	switch (token)
	{
		case TokenType.Minus: return UnaryOp.Negative;
		case TokenType.Not: return UnaryOp.Not;
	}
	
	return undefined;
}

/// @param {Enum.BinaryOp} op
/// @param {Struct.AstExpression} lhs
/// @param {Struct.AstExpression} rhs
function AstExpressionBinaryOp(op, lhs, rhs) : AstExpression(AstExpressionType.BinaryOp) constructor
{
	self.op = op;
	self.lhs = lhs;
	self.rhs = rhs;
	
	static toString = function()
	{
		return $"({self.lhs} {binaryOpSymbolOf(self.op)} {self.rhs})";
	}
}

/// @param {Enum.UnaryOp} op
/// @param {Struct.AstExpression} expr
function AstExpressionUnaryOp(op, expr) : AstExpression(AstExpressionType.UnaryOp) constructor
{
	self.op = op;
	self.expr = expr;
	
	static toString = function()
	{
		return $"{unaryOpNameOf(self.op)}({self.expr})";
	}
}

/// @param {String} name
function AstExpressionReference(name) : AstExpression(AstExpressionType.Reference) constructor
{
	self.name = name;
	
	static toString = function()
	{
		return self.name;
	}
}

/// @param {Struct.Lexer} lexer
function Parser(lexer) constructor
{
	self.lexer = lexer;
	
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
}
