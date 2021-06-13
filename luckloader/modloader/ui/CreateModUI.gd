extends Control

const Util = preload("res://modloader/util.gd")

onready var mod_id := $ModID
onready var mod_name := $ModName
onready var output_path_label := $OutputPath
onready var create_button := $CreateButton

var output_path_root := OS.get_executable_path().get_base_dir()
var output_path: String
var id_regex := RegEx.new()

const template_path := "res://modloader/template/"

func _ready():
	_on_input_changed("")
	id_regex.compile("^[a-z0-9_-]+$")

func _on_input_changed(_new_text):
	output_path = output_path_root.plus_file(get_text(mod_id))
	output_path_label.text = output_path
	
	create_button.text = "Save template for " + get_text(mod_name)
	
	create_button.disabled = are_inputs_invalid()

func _on_create_button_pressed():
	if are_inputs_invalid():
		return
	
	var dir := Directory.new()
	var file := File.new()
	
	if dir.dir_exists(output_path):
		pass # TODO: Warn about override
	else:
		_assert(dir.make_dir_recursive(output_path) == OK, "Failed to create output directory")
	
	_assert(dir.copy(template_path + "export_presets.cfg", output_path.plus_file("export_presets.cfg")) == OK, "Failed to copy export_presets.cfg")
	_assert(dir.copy(template_path + "_.tscn",  output_path.plus_file("_.tscn")) == OK, "Failed to copy _.tscn")
	
	var mod_path := output_path.plus_file("mods").plus_file(mod_id.text)
	dir.make_dir_recursive(mod_path)
	if !dir.dir_exists(mod_path):
		_assert(false, "Failed to create mod folder")
	
	_assert(file.open(template_path + "mods/modnamehere/mod.gd", File.READ) == OK, "Failed to read mod.gd")
	var mod_script_content := file.get_as_text().replace("<modnamehere>", mod_name.text)
	file.close()
	
	_assert(file.open(mod_path.plus_file("mod.gd"), File.WRITE) == OK, "Failed to write mod.gd")
	file.store_string(mod_script_content)
	file.close()
	
	_assert(file.open(template_path + "project.godot", File.READ) == OK, "Failed to read project.godot")
	var project_content := file.get_as_text().replace("<modnamehere>", mod_name.text)
	file.close()
	
	_assert(file.open(output_path.plus_file("project.godot"), File.WRITE) == OK, "Failed to write project.godot")
	file.store_string(project_content)
	file.close()
	
	OS.alert("Template saved successfully!", "Success")

func are_inputs_invalid():
	return mod_id.text.empty() or mod_name.text.empty() or id_regex.search(mod_id.text) == null

static func get_text(input: LineEdit):
	if input.text.empty():
		return "<" + input.placeholder_text + ">"
	else:
		return input.text

static func _assert(condition: bool, message: String):
	if !condition:
		Util._halt_alert(message, "CREATE MOD TEMPLATE")
