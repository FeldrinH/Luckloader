extends "datadump.gd"

func execute():
	datadump_dir = OS.get_executable_path().get_base_dir().plus_file("fulldump")
	
	Util.ensure_dir_exists(datadump_dir)
	
	dump_files("res://")
	dump_files("res://JSON")
	dump_images("res://")
	dump_images("res://icons")
	dump_images("res://buttons")
	dump_translations()
	ProjectSettings.save_custom(datadump_dir.plus_file("project.godot"))
