extends SceneTree

const modloader_version := "v0.1.0"
const expected_version := "Content Patch #5 -- Hotfix #3"
var game_version: String = "<game version not determined yet>"

var exe_dir := OS.get_executable_path().get_base_dir()

const translations := {}
const builtin_translations := {}

var regex := RegEx.new()
var dir_global := Directory.new()

func _init():
	print("MODLOADER: Initializing Lucklike Modloader " + modloader_version)
	print("MODLOADER: Executable directory: " + exe_dir)
	print("MODLOADER: Godot engine version: " + Engine.get_version_info().string)
	
	ensure_dir_exists("user://_loadtemp")
	ensure_dir_exists("user://_patched")
	
	# Extract game version using regex. Dirty hack to avoid having to run game code before patching.
	var main_script = extract_script(copy_and_load("res://Main.tscn"), "Main").source_code
	
	regex.compile("\\sversion_str\\s*=\\s*\"(.*?)\"")
	var matched_version := regex.search(main_script)
	if matched_version == null:
		__halt("Version check failed: Unable to determine game version. This modloader is for game version " + expected_version)
	
	game_version = matched_version.strings[1]
	print("MODLOADER: Game version: " + game_version)
	if expected_version != game_version:
		__halt("Version mismatch: This modloader is for version '" + expected_version + "' but the game is running version '" + game_version + "'")
	
	#attach_hooks()
	
	setup_translations()
	add_translation("flower", "Blurry thing")
	add_translation("flower_desc", "Going live, move out")
	add_translation("cat_desc", "<icon_coin> and meow")
	print(tr("flower"))
	
	load_mods()
	
	print("MODLOADER: Initialization complete")
	
	print("MODLOADER: Starting game")
	change_scene(ProjectSettings.get_setting("application/run/main_scene"))
	#yield(self, "node_added")	

func attach_hooks():
	print("MODLOADER: Patching game code")
	
	var packer := PCKPacker.new()
	packer.pck_start("user://_patched/preload.pck")
	
	var main_scene : = copy_and_load("res://Main.tscn")
	var target_script := extract_script(main_scene, "Reels")
	
	var datetime := str(OS.get_datetime().hour) + ":" + str(OS.get_datetime().minute) + ":" + str(OS.get_datetime().second)
	var new_code := "$0\tprint(\"hello from loaderland reels time of patch " + datetime + "\")\n"
	
	regex.compile("func spin\\(.*?\\n")
	target_script.source_code = regex.sub(target_script.source_code, new_code)
	#print(target_script.source_code)
	
	save_and_pack(packer, main_scene, "res://Main.tscn")
	
	packer.flush(true)
	
	print("MODLOADER: Loading patched code")
	ProjectSettings.load_resource_pack("user://_patched/preload.pck", true)
	
	print("MODLOADER: Patching game code complete")

func load_mods():
	print("MODLOADER: Loading mods")

	__assert(ProjectSettings.load_resource_pack("test.zip", true), "Failed to load test.zip")

	print("MODLOADER: Loading mods complete")

func setup_translations():
	for locale in TranslationServer.get_loaded_locales():
		var tr := Translation.new()
		tr.locale = locale
		translations[locale] = tr
		TranslationServer.add_translation(tr)
	
	for tr_path in ProjectSettings["locale/translations"]:
		var tr := load(tr_path)
		builtin_translations[tr.locale] = tr

func add_translation(key: String, value: String, locale: String = "en"):
	if !translations.has(locale):
		print("MODLOADER: Warning: Attempt to add translation to unknown locale ", locale)
		return
	translations[locale].add_message(key, value)
	remove_builtin_translation(key, locale)

func remove_builtin_translation(key: String, locale: String = "en"):
	if !builtin_translations.has(locale):
		print("MODLOADER: Warning: Attempt to remove builtin translation from unknown locale ", locale)
		return
	var tr: PHashTranslation = builtin_translations[locale]
	if tr.get_message(key) == "":
		return
	compressed_translation_remove_message(key, tr)

func extract_script(scene: PackedScene, node_name: String) -> GDScript:
	var state: SceneState = scene.get_state()
	
	var node_idx := -1
	var node_count := state.get_node_count()
	for i in node_count:
		if state.get_node_name(i) == node_name:
			node_idx = i
			break
	__assert(node_idx != -1, "Node not found while extracting script from packed scene")
	
	var extracted_script: GDScript = null
	var property_count := state.get_node_property_count(node_idx)
	for i in property_count:
		if state.get_node_property_name(node_idx, i) == "script":
			extracted_script = state.get_node_property_value(node_idx, i)
			break
	__assert(extracted_script is GDScript, "Extracted script is not GDScript")
	__assert(extracted_script.has_source_code(), "Extracted script does not have source code")
	
	return extracted_script

func ensure_dir_exists(dir_path: String):
	if !dir_global.dir_exists(dir_path):
		__assert(dir_global.make_dir(dir_path) == OK, "Failed to create directory " + dir_path)

func save_and_pack(packer: PCKPacker, res: Resource, target_path: String):
	var save_path := "user://_patched/" + target_path.trim_prefix("res://").replace("/", "_").replace("\\", "_")
	__assert(ResourceSaver.save(save_path, res) == OK, "Failed to save resource to " + save_path)
	__assert(packer.add_file(target_path, save_path) == OK, "Failed to pack resource to " + res.resource_path)

func copy_and_load(res_path: String) -> Resource:
	var temp_path := "user://_loadtemp/" + res_path.trim_prefix("res://")
	__assert(dir_global.copy(res_path, temp_path) == OK, "Failed to copy " + res_path + " to " + temp_path)
	return load(temp_path)

const uint32_limit := 0x100000000

# Function for removing a message from a PHashTranslation based on key.
# Based on get_message implementation in Godot engine source code.
func compressed_translation_remove_message(message_key: String, tr: PHashTranslation):
	var hash_raw: int = string_hash(0, message_key)
	var hash_idx: int = hash_raw % tr.hash_table.size()
	#print(h, " -> ", tr.hash_table[h])
	
	var bucket_idx: int = tr.hash_table[hash_idx]
	var bucket_size: int = tr.bucket_table[bucket_idx]
	var bucket_func: int = tr.bucket_table[bucket_idx + 1]
	var expected_key := string_hash(bucket_func, message_key)
	#print("expected ", expected_key)
	for i in bucket_size:
		var key_idx: int = bucket_idx + 2 + i * 4
		var key: int = tr.bucket_table[key_idx]
		if key < 0:
			key += uint32_limit
		#print(key)
		if key == expected_key:
			#print("Found!")
			tr.bucket_table[key_idx] = 0
			return

# Hashing function used by PHashTranslation.
# Implementation copied from Godot engine source code and adapted for GDScript.
func string_hash(d: int, string: String) -> int:
	if d == 0:
		d = 0x1000193
	
	for ch in string.to_utf8():
		#print(d, " ", (d * 0x1000193) ," ",((d * 0x1000193) % maxvalue), " ", (((d * 0x1000193) % maxvalue) ^ ch) % maxvalue)
		d = (((d * 0x1000193) % uint32_limit) ^ ch) % uint32_limit;
	
	return d;

func __assert(condition: bool, message: String):
	if !condition:
		__halt(message)

func __halt(message: String):
	# Output error message
	push_error("MODLOADER RUNTIME ERROR: " + message)
	# Cause an intentional null pointer exception, to halt script execution
	var t1 = null
	t1.fail_runtime_check()
