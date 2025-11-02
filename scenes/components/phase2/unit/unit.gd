extends Entity
class_name Unit

@export_subgroup("Unit Action")
@export var action_array:Array[Action]
#to check if has acted, check if action_count<action_max
@export var action_max:int = 1
var action_count:int = action_max

@export_subgroup("Unit Movement")
@export var move_max:int = 5
var move_count:int = move_max

@export_subgroup("Unit Cosmetics")
@export var unit_name:String = "Joe"
@export var icon_sprite:Texture2D = null

@export_subgroup("Resource")
##this variable isnt required, only useful if the unit spawns on the first
@export var u_res:UnitResource = null

# Checks if unit has actions remaining
func can_act() -> bool:
	return action_count > 1

# Checks if unit has moves remaining
func can_move() -> bool:
	return move_count > 1

func load_unit_res(unit_res:UnitResource = null):
	if not unit_res:
		return
	#unit variables
	action_array = unit_res.action_array.duplicate(true)
	action_max = unit_res.action_max
	action_count = action_max
	move_max = unit_res.move_max
	move_count = move_max
	icon_sprite = unit_res.icon_sprite
	unit_name = unit_res.unit_name
	#entity variables
	base_health = unit_res.base_health
	health = base_health
	immortal = unit_res.immortal
	entity_shape = unit_res.entity_shape
	anim_frames = unit_res.anim_frames
	anim_sprite.sprite_frames = anim_frames
	if anim_frames.get_animation_names().has("Idle"):
		anim_sprite.animation = "Idle"
	
	
