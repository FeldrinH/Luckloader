extends SceneTree

var modloader = null

var exe_dir := OS.get_executable_path().get_base_dir()

func _initialize():
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
		
		connect("node_added", self, "modloader_execute_after_start", [], CONNECT_DEFERRED | CONNECT_ONESHOT)
	elif mode == "-assetdump" or mode == "-fulldump":
		print("BOOTSTRAP: Running assetdump")
		
		var assetdump = load("res://modloader/fulldump.gd" if mode == "-fulldump" else "res://modloader/fulldump.gd").new()
		
		assetdump.execute()
		
		create_timer(4).connect("timeout", self, "quit", [], CONNECT_DEFERRED | CONNECT_ONESHOT)
	elif mode == "-createmod":
		
	else:
		_halt("Unknown bootstrap mode: '" + mode + "'")

func modloader_execute_after_start(_arg):
	modloader.execute_after_start()

func get_mode():
	for argument in OS.get_cmdline_args():
		if argument == "-datadump" or argument == "-fulldump" or argument == "-createmod":
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
