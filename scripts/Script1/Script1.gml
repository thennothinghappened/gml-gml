
var input = @'
	var struct = {
		stuff: "whoa",
		idkLol: function()
		{
			return 3;
		}
	};
	
	struct.blah = function() {
		return {
			innerFunc: function() {
				print("hello!");
			}
		};
	};

	struct[$ "blah" + "uwu"] = "owo";
	print(struct[$ "blah" + "uwu"]);

	print("testing conditional");

	if (true)
	{
		print("1 is indeed yes");
	}
	else
	{
		print("1 is not???");
	}

	return struct;
';

var lexer = new Lexer(input);
var parser = new Parser(lexer);
var ast = parser.parse();

var interpreter = new Interpreter(ast)
	.define("print", show_message);

var result = interpreter.execute();
show_message($"Program returned: {result}");
game_end();

result.blah().innerFunc();
