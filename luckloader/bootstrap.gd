extends SceneTree

var modloader = null

var exe_dir := OS.get_executable_path().get_base_dir()

func _init():
	print("BOOTSTRAP: Executable directory: " + exe_dir)
	print("BOOTSTRAP: Godot engine version: " + Engine.get_version_info().string)
	
	_assert(ProjectSettings.load_resource_pack(exe_dir.plus_file("luckloader/modloader.zip"), true), "Failed to load internals")
	
	var mode = get_mode()
	if mode == null:
		print("BOOTSTRAP: Running modloader")
		
		modloader = load("res://modloader/modloader.gd").new(self)
		
		modloader.execute_before_start()
		
		print("BOOTSTRAP: Starting game")
		change_scene(ProjectSettings.get_setting("application/run/main_scene"))
		yield(self, "node_added")
		
		modloader.execute_after_start()
	elif mode == "-datadump":
		print("BOOTSTRAP: Running datadump")
		
		var datadump = load("res://modloader/datadump.gd").new()
		
		datadump.execute()
		
		yield(create_timer(5), "timeout")
		quit()
	else:
		_halt("Unknown bootstrap mode: '" + mode + "'")

func get_mode():
	for argument in OS.get_cmdline_args():
		if argument == "-datadump":
			return argument
	return null

static func _assert(condition: bool, message: String):
	if !condition:
		_halt(message)

static func _halt(message: String):
	# Output error message
	push_error("BOOTSTRAP RUNTIME ERROR: " + message)
	# Cause an intentional null pointer exception, to halt script execution
	var t1 = null
	t1.fail_runtime_check()