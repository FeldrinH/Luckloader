extends "res://Item_Item.gd"

onready var modloader: Reference = get_tree().modloader
onready var add_conditional_effects_hooks = modloader.hooks["add_item_effects"]

func add_conditional_effects():
	if modloader.run_hook_bool_1(add_conditional_effects_hooks, self):
		add_effect({"comparisons": [{"a": "destroyed", "b": true}], "value_to_change": "alpha", "diff": 0.3})
	else:
		.add_conditional_effects()
