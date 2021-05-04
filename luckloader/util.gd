extends Reference


static func ensure_dir_exists(dir_path: String):
	var dir := Directory.new()
	if !dir.dir_exists(dir_path):
		_assert(dir.make_dir(dir_path) == OK, "Failed to create directory " + dir_path)

static func read_json(file_path: String):
	var data_file := File.new()
	_assert(data_file.open(file_path, File.READ) == OK, "Failed to open " + file_path)
	var parse_result := JSON.parse(data_file.get_as_text())
	data_file.close()
	_assert(parse_result.error == OK, "Failed to parse " + file_path + " as JSON")
	return parse_result.result


static func _assert(condition: bool, message: String):
	if !condition:
		_halt(message)

static func _halt(message: String):
	# Output error message
	push_error("MODLOADER UTIL RUNTIME ERROR: " + message)
	# Cause an intentional null pointer exception, to halt script execution
	var t1 = null
	t1.fail_runtime_check()
