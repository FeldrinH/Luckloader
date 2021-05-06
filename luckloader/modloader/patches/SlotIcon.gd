extends "res://Slot Icon_Slot Icon.gd"

onready var modloader: Reference = get_tree().modloader

func add_conditional_effects():
	.add_conditional_effects()
	
	modloader.emit_signal("add_conditional_effects", self, get_adjacent_icons())
	
	#print(self, " ", type, " hook add_conditional_effects")
