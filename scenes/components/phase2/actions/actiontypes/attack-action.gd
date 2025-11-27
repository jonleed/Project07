extends Action
class_name Attackaction
@export var base_dmg:int = 0:
	set(value):
		base_dmg = value
		dmg = float(base_dmg)*dmg_mult
@export var dmg_mult:float = 1.0:
	set(value):
		dmg_mult = value
		dmg = float(base_dmg)*dmg_mult
var dmg : float = float(base_dmg)*dmg_mult
@export var heal_on_kill:float = 0.0
@export var all_tile_attack:bool = false
