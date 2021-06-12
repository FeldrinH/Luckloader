extends "datadump.gd"

func _init():
	datadump_dir = OS.get_executable_path().get_base_dir().plus_file("assetdump")

func execute():
	Util.ensure_dir_exists(datadump_dir)
	
	dump_files("res://JSON")
	dump_images("res://")
	dump_images("res://icons")
	dump_translations()
