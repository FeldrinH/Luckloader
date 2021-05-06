extends Reference

const display_name := "Example Mod"
const version := "v0.1.0"

func load(modloader, tree):
	modloader.add_hook("symbol_add_effects", self, "symbol_add_effects")
	modloader.add_hook("item_add_effects", self, "item_add_effects")

func symbol_add_effects(icon, adj_icons):
	print(icon.type, " ", icon.reels.conditional_effects[icon.grid_position.y][icon.grid_position.x])

func item_add_effects(item):
	print(item.type, " ")
