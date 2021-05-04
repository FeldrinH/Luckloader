extends Reference

var tree: SceneTree = null
const Util = preload("res://modloader/util.gd")

const modloader_version := "v0.2.0"
const expected_version := "Content Patch #5 -- Hotfix #3"
var game_version: String = "<game version not determined yet>"

var exe_dir := OS.get_executable_path().get_base_dir()

var symbols: Dictionary
var items: Dictionary
var emails: Dictionary

const mods := []
const translations := {}
const builtin_translations := {}

var _dir := Directory.new()

func _init(tree: SceneTree):
	self.tree = tree
	print(tree)
	print(self.tree)

func execute_before_start():
	print("MODLOADER: Initializing Luckloader " + modloader_version)
	
	_assert(ProjectSettings.load_resource_pack(exe_dir.plus_file("luckloader/modloader.zip"), true), "Failed to load modloader internals")
	
	Util.ensure_dir_exists("user://_loadtemp")
	Util.ensure_dir_exists("user://_patched")
	
	# Extract game version using regex. Dirty hack to avoid having to run game code before patching.
	var main_script = extract_script(copy_and_load("res://Main.tscn"), "Main").source_code
	
	var regex := RegEx.new()
	regex.compile("\\sversion_str\\s*=\\s*\"(.*?)\"")
	var matched_version := regex.search(main_script)
	if matched_version == null:
		_halt("Version check failed: Unable to determine game version. This modloader is for game version " + expected_version)
	
	game_version = matched_version.strings[1]
	print("MODLOADER: Game version: " + game_version)
	if expected_version != game_version:
		_halt("Version mismatch: This modloader is for version '" + expected_version + "' but the game is running version '" + game_version + "'")
	
	#patch_preload()
	
	setup_translations()
	
	setup_json()
	print(items.size())
	print(symbols.size())
	print(emails.size())
	
	#loads_mods()
	
	patch_postload()

func execute_after_start():
	print("MODLOADER: Adding modloader UI overlay")
	tree.current_scene.add_child(load("res://modloader/MainMenuOverlay.tscn").instance())
	
	postload_mods()
	
	print("MODLOADER: Initialization complete")

func patch_preload():
	print("MODLOADER: Patching game code")
	
	var packer := PCKPacker.new()
	packer.pck_start("user://_patched/preload.pck")
	
	var main_scene : = copy_and_load("res://Main.tscn")
	var target_script := extract_script(main_scene, "Reels")
	
	var datetime := str(OS.get_datetime().hour) + ":" + str(OS.get_datetime().minute) + ":" + str(OS.get_datetime().second)
	var new_code := "$0\tprint(\"hello from loaderland reels time of patch " + datetime + "\")\n"
	
	var regex := RegEx.new()
	regex.compile("func spin\\(.*?\\n")
	target_script.source_code = regex.sub(target_script.source_code, new_code)
	#print(target_script.source_code)
	
	save_and_pack_resource(packer, main_scene, "res://Main.tscn")
	
	packer.flush(true)
	
	print("MODLOADER: Loading patched code")
	_assert(ProjectSettings.load_resource_pack("user://_patched/preload.pck", true), "Failed to load patched code")
	
	print("MODLOADER: Patching game code complete")

func patch_postload():
	print("MODLOADER: Patching game data")
	
	var packer := PCKPacker.new()
	packer.pck_start("user://_patched/postload.pck")
	
	save_and_pack_json(packer, symbols, "res://JSON/Symbols - JSON.json")
	save_and_pack_json(packer, items, "res://JSON/Items - JSON.json")
	save_and_pack_json(packer, emails, "res://JSON/Emails - JSON.json")
	
	packer.flush(true)
	
	print("MODLOADER: Loading patched data")
	_assert(ProjectSettings.load_resource_pack("user://_patched/postload.pck", true), "Failed to load patched data")
	
	print("MODLOADER: Patching game data complete")

func load_mods():
	print("MODLOADER: Loading mods")

	_assert(ProjectSettings.load_resource_pack("test.zip", true), "Failed to load test.zip")

	print("MODLOADER: Loading mods complete")

func postload_mods():
	pass

func setup_translations():
	for locale in TranslationServer.get_loaded_locales():
		var tr := Translation.new()
		tr.locale = locale
		translations[locale] = tr
		TranslationServer.add_translation(tr)
	
	for tr_path in ProjectSettings["locale/translations"]:
		var tr := load(tr_path)
		builtin_translations[tr.locale] = tr

func setup_json():
	symbols = Util.read_json("res://JSON/Symbols - JSON.json")
	items = Util.read_json("res://JSON/Items - JSON.json")
	emails = Util.read_json("res://JSON/Emails - JSON.json")

func add_symbol(name: String, data: Dictionary):
	if !(data.has("value") and data.has("values") and data.has("rarity") and data.has("groups")):
		_halt("Attempt to add invalid symbol " + str(data))
	
	symbols[name] = data

func add_item(name: String, data: Dictionary):
	if !(data.has("values") and data.has("rarity") and data.has("groups")):
		_halt("Attempt to add invalid item " + str(data))
	
	items[name] = data

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

static func extract_script(scene: PackedScene, node_name: String) -> GDScript:
	var state: SceneState = scene.get_state()
	
	var node_idx := -1
	var node_count := state.get_node_count()
	for i in node_count:
		if state.get_node_name(i) == node_name:
			node_idx = i
			break
	_assert(node_idx != -1, "Node not found while extracting script from packed scene")
	
	var extracted_script: GDScript = null
	var property_count := state.get_node_property_count(node_idx)
	for i in property_count:
		if state.get_node_property_name(node_idx, i) == "script":
			extracted_script = state.get_node_property_value(node_idx, i)
			break
	_assert(extracted_script is GDScript, "Extracted script is not GDScript")
	_assert(extracted_script.has_source_code(), "Extracted script does not have source code")
	
	return extracted_script

func save_and_pack_resource(packer: PCKPacker, res: Resource, target_path: String):
	var save_path := "user://_patched/" + target_path.trim_prefix("res://").replace("/", "_").replace("\\", "_")
	_assert(ResourceSaver.save(save_path, res) == OK, "Failed to save resource to " + save_path)
	_assert(packer.add_file(target_path, save_path) == OK, "Failed to pack resource to " + target_path)

func save_and_pack_json(packer: PCKPacker, json_data, target_path: String):
	var save_path := "user://_patched/" + target_path.trim_prefix("res://").replace("/", "_").replace("\\", "_")
	
	var file := File.new()
	_assert(file.open(save_path, File.WRITE) == OK, "Failed to open file " + save_path + " for writing")
	file.store_string(JSON.print(json_data, "  "))
	file.close()
	
	_assert(packer.add_file(target_path, save_path) == OK, "Failed to pack resource to " + target_path)

func copy_and_load(res_path: String) -> Resource:
	var temp_path := "user://_loadtemp/" + res_path.trim_prefix("res://")
	_assert(_dir.copy(res_path, temp_path) == OK, "Failed to copy " + res_path + " to " + temp_path)
	return load(temp_path)

const uint32_limit := 0x100000000

# Function for removing a message from a PHashTranslation based on key.
# Based on get_message implementation in Godot engine source code.
static func compressed_translation_remove_message(message_key: String, tr: PHashTranslation):
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
static func string_hash(d: int, string: String) -> int:
	if d == 0:
		d = 0x1000193
	
	for ch in string.to_utf8():
		#print(d, " ", (d * 0x1000193) ," ",((d * 0x1000193) % maxvalue), " ", (((d * 0x1000193) % maxvalue) ^ ch) % maxvalue)
		d = (((d * 0x1000193) % uint32_limit) ^ ch) % uint32_limit;
	
	return d;

static func _assert(condition: bool, message: String):
	if !condition:
		_halt(message)

static func _halt(message: String):
	# Output error message
	push_error("MODLOADER RUNTIME ERROR: " + message)
	# Cause an intentional null pointer exception, to halt script execution
	var t1 = null
	t1.fail_runtime_check()
