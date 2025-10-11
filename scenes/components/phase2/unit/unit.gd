extends Entity
class_name Unit

@export var action_array:Array[Action]

#to check if has acted, check if action_count<action_max
@export var action_max:int = 1
var action_count:int = action_max
@export var move_max:int = 5
var move_count:int = move_max

@export var icon_sprite:Texture2D = null

# Checks if unit has actions remaining
func can_act() -> bool:
	return action_count > 1

# Checks if unit has moves remaining
func can_move() -> bool:
	return move_count > 1

func load_unit_res(unit_res:UnitResource):
	#unit variables
	action_array = unit_res.action_array.duplicate(true)
	action_max = unit_res.action_max
	action_count = action_max
	move_max = unit_res.move_max
	move_count = move_max
	icon_sprite = unit_res.icon_sprite
	#entity variables
	base_health = unit_res.base_health
	health = base_health
	immortal = unit_res.immortal
	entity_shape = unit_res.entity_shape
	anim_frames = unit_res.anim_frames
	anim_sprite.sprite_frames = anim_frames
	if anim_frames.get_animation_names().has("Idle"):
		anim_sprite.animation = "Idle"
	
	
