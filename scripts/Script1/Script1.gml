
var input = @'
	var aaaa = 3;
	var blah = "idk lol";

	print(blah);

	function blahh(stuff, moreStuff)
	{
		return stuff + moreStuff;
	}

	print(blahh);

	function nested()
	{
		return function(a, b)
		{
			return a + b;
		};
	}

	print(nested()(2, 3));

	return blahh("uwu" + "owo", "stuff");
';

var lexer = new Lexer(input);
var parser = new Parser(lexer);
var ast = parser.parse();

var interpreter = new Interpreter(ast)
	.define("print", show_message);

var result = interpreter.execute();
show_message($"Program returned: {result}");
game_end();
