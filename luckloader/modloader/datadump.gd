extends Reference

const Util = preload("res://modloader/util.gd")

var datadump_dir: String

var regex := RegEx.new()
var dir := Directory.new()

func dump_file(file_path: String):
	var target_path := datadump_dir.plus_file(file_path.trim_prefix("res://"))
	_assert(dir.copy(file_path, target_path) == OK, "Failed to dump file " + file_path + " to " + target_path)

func dump_files(folder_path: String):
	print("DATADUMP: Loading folder " + folder_path)
	
	Util.ensure_dir_exists(datadump_dir.plus_file(folder_path.trim_prefix("res://")))
	
	_assert(dir.open(folder_path) == OK, "Failed to open " + folder_path)
	_assert(dir.list_dir_begin(true) == OK, "list_dir_begin failed")
	var found_name := dir.get_next()
	while found_name != "":
		if !dir.current_is_dir():
			if found_name != "project.binary":
				print("DATADUMP: Found file: " + found_name)
				dump_file(folder_path.plus_file(found_name))
		
		found_name = dir.get_next()
	
	print("DATADUMP: Dumped files in folder " + folder_path)

func dump_images(folder_path: String):
	Util.ensure_dir_exists(datadump_dir.plus_file(folder_path.trim_prefix("res://")))
	
	regex.compile("(.*)\\.import")
	
	print("DATADUMP: Loading images from " + folder_path)
	
	_assert(dir.open(folder_path) == OK, "Failed to open " + folder_path)
	_assert(dir.list_dir_begin(true) == OK, "list_dir_begin failed")
	var found_name := dir.get_next()
	while found_name != "":
		var matched := regex.search(found_name)
		if matched != null:
			var file_path: String = folder_path.plus_file(matched.strings[1])
			var res: Texture = load(file_path)
			if res is Texture:
				print("DATADUMP: Found image: " + file_path)
				res.get_data().save_png(datadump_dir.plus_file(file_path.trim_prefix("res://")))
				dump_file(file_path + ".import")
		
		found_name = dir.get_next()
		
	print("DATADUMP: Dumped all images from " + folder_path)

func dump_translations():
	print("DATADUMP: Loading translations")
	
	var known_keys := []
	for key in Util.read_json("res://JSON/Items - JSON.json"):
		known_keys.append(key)
		known_keys.append(key + "_desc")
	for key in Util.read_json("res://JSON/Symbols - JSON.json"):
		known_keys.append(key)
		known_keys.append(key + "_desc")
	
	for locale in TranslationServer.get_loaded_locales():
		print("DATADUMP: Found translation: " + locale)
		TranslationServer.set_locale(locale)
		
		var out_file := File.new()
		_assert(out_file.open(datadump_dir.plus_file("translation-" + locale + ".txt"), File.WRITE) == OK, "Failed to open output file for translation")
		for key in known_keys:
			var tr := TranslationServer.translate(key)
			if tr != key:
				out_file.store_line(key + " -> " + tr)
		out_file.close()
		
	print("DATADUMP: Dumped all translations")

func _assert(condition: bool, message: String):
	if !condition:
		_halt(message)

func _halt(message: String):
	# Output error message
	push_error("DATADUMP RUNTIME ERROR: " + message)
	# Cause an intentional null pointer exception, to halt script execution
	var t1 = null
	t1.fail_runtime_check()
