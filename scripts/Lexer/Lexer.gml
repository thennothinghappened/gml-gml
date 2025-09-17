
enum TokenType
{
	Identifier,
	String,
	Number,
	OpenParenthesis,
	CloseParenthesis,
	OpenBlock,
	CloseBlock,
	OpenSquareBracket,
	OpenStructMemberAccess,
	CloseSquareBracket,
	SingleEquals,
	DoubleEquals,
	GreaterThan,
	LessThan,
	GreaterOrEqual,
	LessOrEqual,
	Plus,
	Minus,
	Multiply,
	Divide,
	Not,
	Semicolon,
	Colon,
	Comma,
	Period,
	Unknown
}

/// @param {Enum.TokenType} tokenType
/// @returns {String}
function tokenNameOf(tokenType)
{
	static tokenNames = undefined;
	
	if (is_undefined(tokenNames))
	{
		tokenNames = [];
		tokenNames[TokenType.Identifier] = "Identifier";
		tokenNames[TokenType.String] = "String";
		tokenNames[TokenType.Number] = "Number";
		tokenNames[TokenType.OpenParenthesis] = "OpenParenthesis";
		tokenNames[TokenType.CloseParenthesis] = "CloseParenthesis";
		tokenNames[TokenType.OpenBlock] = "OpenBlock";
		tokenNames[TokenType.CloseBlock] = "CloseBlock";
		tokenNames[TokenType.OpenSquareBracket] = "OpenSquareBracket";
		tokenNames[TokenType.OpenStructMemberAccess] = "OpenStructMemberAccess";
		tokenNames[TokenType.CloseSquareBracket] = "CloseSquareBracket";
		tokenNames[TokenType.SingleEquals] = "SingleEquals";
		tokenNames[TokenType.DoubleEquals] = "DoubleEquals";
		tokenNames[TokenType.GreaterThan] = "GreaterThan";
		tokenNames[TokenType.LessThan] = "LessThan";
		tokenNames[TokenType.GreaterOrEqual] = "GreaterOrEqual";
		tokenNames[TokenType.LessOrEqual] = "LessOrEqual";
		tokenNames[TokenType.Plus] = "Plus";
		tokenNames[TokenType.Minus] = "Minus";
		tokenNames[TokenType.Multiply] = "Multiply";
		tokenNames[TokenType.Divide] = "Divide";
		tokenNames[TokenType.Not] = "Not";
		tokenNames[TokenType.Semicolon] = "Semicolon";
		tokenNames[TokenType.Colon] = "Colon";
		tokenNames[TokenType.Comma] = "Comma";
		tokenNames[TokenType.Period] = "Period";
		tokenNames[TokenType.Unknown] = "Unknown";
	}
	
	return tokenNames[tokenType];
}

/// @param {Enum.TokenType} type
/// @param {Any} [data]
function Token(type, data) constructor
{
	self.type = type;
	self.data = data;
	
	static toString = function()
	{
		var typeName = tokenNameOf(self.type);
		
		if (is_undefined(self.data))
		{
			return typeName;
		}
		
		return $"{typeName}({self.data})";
	}
}

function Lexer(text) constructor
{
	self.text = text;
	self.textLength = string_length(text);
	self.index = 1;
	
	self.__startRow = 1;
	self.__startColumn = 1;
	self.__endRow = 1;
	self.__endColumn = 1;
	
	self.__prevStartRow = 1;
	self.__prevStartColumn = 1;
	self.__prevEndRow = 1;
	self.__prevEndColumn = 1;
	
	self.__nextToken = undefined;
	TYPEHINT self.__nextToken = new Token(TokenType.Plus);
	
	/// @returns {Struct.Token}
	static next = function()
	{
		if (!is_undefined(self.__nextToken))
		{
			var token = self.__nextToken;
			self.__nextToken = undefined;
			
			return token;
		}
		
		self.__prevStartRow = self.__startRow;
		self.__prevStartColumn = self.__startColumn;
		self.__prevEndRow = self.__endRow;
		self.__prevEndColumn = self.__endColumn;
		
		self.__skipWhitespace();
		
		self.__startColumn = self.__endColumn;
		self.__startRow = self.__endRow;
		
		var char = self.__peekChar();
		
		if (is_undefined(char))
		{
			return undefined;
		}
		
		switch (char)
		{
			case "(":
				self.__nextChar();
				return new Token(TokenType.OpenParenthesis);
			
			case ")":
				self.__nextChar();
				return new Token(TokenType.CloseParenthesis);
			
			case "{":
				self.__nextChar();
				return new Token(TokenType.OpenBlock);
			
			case "}":
				self.__nextChar();
				return new Token(TokenType.CloseBlock);
			
			case "[":
				self.__nextChar();
				
				if (self.__acceptChar("$"))
				{
					return new Token(TokenType.OpenStructMemberAccess);
				}
				
				return new Token(TokenType.OpenSquareBracket);
			
			case "]":
				self.__nextChar();
				return new Token(TokenType.CloseSquareBracket);
			
			case "=":
				self.__nextChar();
			
				if (self.__peekChar() == "=")
				{
					self.__nextChar();
					return new Token(TokenType.DoubleEquals);
				}
			
				return new Token(TokenType.SingleEquals);
			
			case ">":
				self.__nextChar();
			
				if (self.__acceptChar("="))
				{
					return new Token(TokenType.GreaterOrEqual);
				}
			
				return new Token(TokenType.GreaterThan);
			
			case "<":
				self.__nextChar();
			
				if (self.__acceptChar("="))
				{
					return new Token(TokenType.LessOrEqual);
				}
			
				return new Token(TokenType.LessThan);
				
			case ";":
				self.__nextChar();
				return new Token(TokenType.Semicolon);
			
			case ":":
				self.__nextChar();
				return new Token(TokenType.Colon);
			
			case "+":
				self.__nextChar();
				return new Token(TokenType.Plus);
			
			case "-":
				self.__nextChar();
				return new Token(TokenType.Minus);
			
			case "*":
				self.__nextChar();
				return new Token(TokenType.Multiply);
			
			case "/":
				self.__nextChar();
				
				if (self.__acceptChar("/"))
				{
					self.__consumeWhile(function(char)
					{
						return char != "\n";
					})
					
					return self.next();
				}
				else
				{
					return new Token(TokenType.Divide);
				}
			
			case "!":
				self.__nextChar();
				return new Token(TokenType.Not);
			
			case ",":
				self.__nextChar();
				return new Token(TokenType.Comma);
			
			case ".":
				self.__nextChar();
				return new Token(TokenType.Period);
			
			case "\"":
				self.__nextChar();
			
				static escapeCharMap = {
					"n": "\n",
					"t": "\t"
				};
				
				var escapeNext = false;
				var str = "";
			
				while (true)
				{
					char = self.__nextChar();
					
					if (char == undefined)
					{
						throw "Unexpected EOF in string";
					}
					
					if (!escapeNext)
					{
						if (char == "\"")
						{
							break;
						}
						
						if (char == "\\")
						{
							escapeNext = true;
							continue;
						}
					}
					else
					{
						escapeNext = false;
						
						if (struct_exists(escapeCharMap, char))
						{
							char = escapeCharMap[$ char];
						}
					}
					
					str += char;
				}
			
				return new Token(TokenType.String, str);
		}
		
		if ((char == "_") || (string_letters(char) == char))
		{
			var identifier = self.__consumeWhile(function(char)
			{
				return (char == "_") || (string_lettersdigits(char) == char);
			});
			
			return new Token(TokenType.Identifier, identifier);
		}
		
		if (string_digits(char) == char)
		{
			var numberString = self.__consumeWhile(function(char)
			{
				return (char == ".") || (string_digits(char) == char);
			});
			
			return new Token(TokenType.Number, real(numberString));
		}
		
		self.__nextChar();
		return new Token(TokenType.Unknown, char);
	}
	
	/// @returns {Struct.Token}
	static peek = function()
	{
		if (is_undefined(self.__nextToken))
		{
			self.__nextToken = self.next();
		}
		
		return self.__nextToken;
	}
	
	/// @returns {Real}
	static startRow = function()
	{
		if (is_undefined(self.__nextToken))
		{
			return self.__startRow;
		}
		else
		{
			return self.__prevStartRow;
		}
	}
	
	/// @returns {Real}
	static endRow = function()
	{
		if (is_undefined(self.__nextToken))
		{
			return self.__endRow;
		}
		else
		{
			return self.__prevEndRow;
		}
	}
	
	/// @returns {Real}
	static startColumn = function()
	{
		if (is_undefined(self.__nextToken))
		{
			return self.__startColumn;
		}
		else
		{
			return self.__prevStartColumn;
		}
	}
	
	/// @returns {Real}
	static endColumn = function()
	{
		if (is_undefined(self.__nextToken))
		{
			return self.__endColumn;
		}
		else
		{
			return self.__prevEndColumn;
		}
	}
	
	/// @ignore
	static __skipWhitespace = function()
	{
		self.__consumeWhile(function(char)
		{
			static whitespace = [" ", "\t", "\r", "\n"];
			return array_contains(whitespace, char);
		});
	}
	
	/// @ignore
	/// @returns {String}
	static __consumeWhile = function(predicate)
	{
		var startIndex = self.index;
		var char = self.__peekChar();
		
		while (!is_undefined(self.__peekChar()) && predicate(self.__peekChar()))
		{
			self.__nextChar();
		}
		
		return string_copy(self.text, startIndex, (self.index - startIndex));
	}
	
	/// @ignore
	/// @returns {String}
	static __peekChar = function()
	{
		if (self.index > self.textLength)
		{
			return undefined;
		}
		
		return string_char_at(self.text, self.index);
	}
	
	/// @ignore
	/// @returns {String}
	static __nextChar = function()
	{
		var char = self.__peekChar();
		
		if (is_undefined(char))
		{
			return undefined;
		}
		
		switch (char)
		{
			case "\n":
				self.__endRow += 1;
				self.__endColumn = 1;
			break;
			
			case "\t":
				self.__endColumn += 4;
			break;
			
			default:
				self.__endColumn += 1;
			break;
		}
		
		self.index += 1;
		return char;
	}
	
	/// @returns {Bool}
	static __acceptChar = function(expected)
	{
		if (self.__peekChar() == expected)
		{
			self.__nextChar();
			return true;
		}
		
		return false;
	}
	
	static formatOffendingArea = function(
		startRow = self.startRow(),
		startColumn = self.startColumn(),
		endRow = self.endRow(),
		endColumn = self.endColumn(),
		contextAbove = 2,
		contextBelow = 1
	) {
		if (startRow - contextAbove < 1)
		{
			contextAbove -= (startRow - 1);
		}
		
		var tempLexer = new Lexer(self.text);
		
		while (tempLexer.endRow() < (startRow - contextAbove))
		{
			if (tempLexer.__nextChar() == undefined)
			{
				break;
			}
		}
		
		var lineStartIndex = tempLexer.index;
		var lines = [];
		
		while (tempLexer.endRow() <= (endRow + contextBelow))
		{
			var char = tempLexer.__nextChar();
			
			if (char == undefined)
			{
				break;
			}
			
			if (char == "\n")
			{
				array_push(lines, string_copy(tempLexer.text, lineStartIndex, tempLexer.index - lineStartIndex));
				lineStartIndex = tempLexer.index;
			}
		}
		
		var closure = {
			contextAbove,
			startRow,
			endRow,
			startColumn,
			endColumn,
		};
		
		var linesAndUnderlines = array_map(lines, method(closure, function(unformattedLine, lineIndex)
		{
			var row = (lineIndex + startRow - contextAbove);
			var lineLength = string_length(unformattedLine);
			
			var line = string_format(row, 4, 0) + " | " + string_replace_all(unformattedLine, "\t", "    ");
			
			if (row == startRow)
			{
				if (startRow == endRow)
				{
					return $"{line}       {string_repeat(" ", startColumn - 1) + string_repeat("~", endColumn - startColumn)}\n";
				}
				return $"{line}       {string_repeat(" ", startColumn - 1) + string_repeat("~", lineLength - startColumn)}\n";
			}
			
			if (row == endRow)
			{
				return $"{line}       {string_repeat("~", endColumn - 1) + string_repeat(" ", lineLength - endColumn)}\n";
			}
			
			if ((row > startRow) && (row < endRow))
			{
				return $"{line}       {string_repeat("~", lineLength)}\n";
			}
			
			return line;
		}));
		
		return string_join_ext("", linesAndUnderlines);
	}
}
