
var input = @'
	var i = 0;

	while (i < 3)
	{
		i = i + 1;
		print(i);
	}

	repeat (5)
	{
		print("5 times!");
	}

	for (var index = 0; index < 5; index = index + 1)
	{
		print("for loop iter!");
	}

	var outerStructMem = 3;

	var struct = {
		stuff: "whoa",
		outerStructMem,
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

	var array = [2, 3];
	print(array[1]);

	if (true * 1)
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
