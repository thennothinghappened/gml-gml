
var input = @'
	var a = 2, b = 3;
	var c = 4;

	print(b);
';

var lexer = new Lexer(input);
var parser = new Parser(lexer);
var ast = parser.parse();

var interpreter = new Interpreter(ast)
	.define("print", show_debug_message);

var result = interpreter.execute();
show_message($"Program returned: {result}");
game_end();

result.blah().innerFunc();
