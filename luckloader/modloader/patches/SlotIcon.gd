extends "res://Slot Icon_Slot Icon.gd"

onready var modloader: Reference = get_tree().modloader
onready var add_conditional_effects_hooks = modloader.hooks["add_symbol_effects"]

func add_conditional_effects():
	var adj_icons = get_adjacent_icons()
	anim_targets.clear()
	if modloader.run_hook_bool_2(add_conditional_effects_hooks, self, adj_icons):
		if type != "empty":
			add_effect({"comparisons": [{"a": "destroyed", "b": true, "not_prev": true}], "value_to_change": "type", "diff": "empty", "push_front": true})
	else:
		.add_conditional_effects()
