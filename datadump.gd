extends SceneTree

const Util := preload("./util.gd")

var exe_dir := OS.get_executable_path().get_base_dir()
var datadump_dir := exe_dir.plus_file("datadump")

var regex := RegEx.new()
var dir := Directory.new()

func _init():
	Util.ensure_dir_exists(datadump_dir)
	
	dump_folder("res://")
	dump_folder("res://JSON")
	dump_images()
	dump_translations()

func dump_file(file_path: String):
	_assert(dir.copy(file_path, datadump_dir.plus_file(file_path.trim_prefix("res://"))) == OK, "Failed to dump file " + file_path)

func dump_folder(folder_path: String):
	print("DATADUMP: Loading folder " + folder_path)
	
	Util.ensure_dir_exists(datadump_dir.plus_file(folder_path.trim_prefix("res://")))
	
	_assert(dir.open(folder_path) == OK, "Failed to open " + folder_path)
	_assert(dir.list_dir_begin(true) == OK, "list_dir_begin failed")
	var found_name := dir.get_next()
	while found_name != "":
		if !dir.current_is_dir():
			print("DATADUMP: Found file: " + found_name)
			dump_file(folder_path.plus_file(found_name))
		
		found_name = dir.get_next()
	
	print("DATADUMP: Dumped files in folder " + folder_path)

func dump_images():
	Util.ensure_dir_exists(datadump_dir.plus_file("icons"))
	
	regex.compile("(.*)\\.import")
	
	print("DATADUMP: Loading icons")
	
	_assert(dir.open("res://icons") == OK, "Failed to open res://icons")
	_assert(dir.list_dir_begin(true) == OK, "list_dir_begin failed")
	var found_name := dir.get_next()
	while found_name != "":
		var matched := regex.search(found_name)
		if matched != null:
			var file_path: String = "icons".plus_file(matched.strings[1])
			print("DATADUMP: Found image: " + file_path)
			var res: Texture = load("res://" + file_path)
			res.get_data().save_png(datadump_dir.plus_file(file_path))
		
		found_name = dir.get_next()
		
	print("DATADUMP: Dumped all icons")

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
