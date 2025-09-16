
/// @author YellowAfterlife
/// @see https://yal.cc/gamemaker-trace-function-2024/
#macro trace repeat (__trace_1(_GMFUNCTION_, ":" + string(_GMLINE_) + ":")) __trace

function __trace_1(file, line) {
	global.__trace_p = file + line;
	return 1;
}

function __trace() {
	var msg = global.__trace_p;
	
	for (var _argi = 0; _argi < argument_count; _argi ++) {
		msg += " " + string(argument[_argi]);
	}
	
	show_debug_message(msg);
}
