
var input = @'
	var a = 2, b = 3;
	var c = 4;

	c += 1;

	switch (c + 1)
	{
		case 5:
			print("this wont happen");
		break;
		
		case 6:
			print("this will happen");
		
		default:
			print("this will happen due to fallthrough");
		break;
	}

	for (var i = 0; i < 10; i += 1)
	{
		try {
			if (int64(i / 3) == 0)
			{
				print("continuing for " + string(i));
				continue;
			}
			
			//throw "oh no";
			
			print("didnt continue for " + string(i));
			break;
		} catch (err) {
			print("caught err " + string(err));
		} finally {
			print("after!");
		}
	}

	print(c);

	function blah(a)
	{
		print(a);
		
		for (var i = 0; i < argument_count; i += 1)
		{
			print("argument " + string(i) + " = " + string(argument[i]));
		}
	}

	blah(1, 2, 3);
';

var lexer = new Lexer(input);
var parser = new Parser(lexer);
var ast = parser.parse();

var interpreter = new Interpreter(ast)
	.define("print", show_debug_message);

var result = interpreter.execute();
show_message($"Program returned: {result}");
game_end();

//result.blah().innerFunc();
