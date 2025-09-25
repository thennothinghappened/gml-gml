
var input = @'
	var struct = {
		hello: "heyo!"
	};

	with (struct) {
		show_message("within struct: " + string(hello) + ", global is " + string(global == other));
	}

	show_message("in global scope: " + string(self[$ "hello"]));

	var a = 2;
	var struct = {
		structFunction: function() {
			show_message("struct.structFunction :: self = " + string(self) + ", other = " + string(other));
		}
	};

	function blah() {
		show_message("blah :: self = " + string(self) + ", other = " + string(other));
	}

	method({ testStruct: "this is a test struct" }, blah)();
	struct.structFunction();
';

var lexer = new Lexer(input);
var parser = new Parser(lexer);
var ast = parser.parse();

var interpreter = new Interpreter(ast)
	.define("print", show_debug_message)
	.define("show_message", show_message);

var result = interpreter.execute();
show_message($"Program returned: {result}");
game_end();

//result.blah().innerFunc();
