
var input = @'
	var struct = {
		stuff: "whoa",
	};
	
	struct.blah = function() {
		var innerStruct = struct_new();
		innerStruct.innerFunc = function() print("hello!");
		
		return innerStruct;
	};

	return struct;
';

var lexer = new Lexer(input);
var parser = new Parser(lexer);
var ast = parser.parse();

var interpreter = new Interpreter(ast)
	.define("print", show_message)
	.define("struct_new", function() { return {}; })
	.define("struct_get", struct_get)
	.define("struct_set", struct_set);

var result = interpreter.execute();
show_message($"Program returned: {result}");
game_end();

result.blah().innerFunc();
