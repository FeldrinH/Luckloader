extends "datadump.gd"

func execute():
	datadump_dir = OS.get_executable_path().get_base_dir().plus_file("assetdump")
	
	Util.ensure_dir_exists(datadump_dir)
	
	dump_files("res://JSON")
	dump_images("res://icons")
	dump_translations()
