
/// @param {String} text
/// @returns {String}
function indent(text)
{
	return "\t" + string_join_ext("\n\t", string_split(text, "\n"));
}
