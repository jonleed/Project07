extends Contact_Trap
class_name Time_Limited_Trap

@export var turns_active_before_dissipating:int = 3
@onready var trap_sprite:AnimatedSprite2D = $AnimatedSprite2D
var turns_active:int = 0

func process_turn() -> void:
	if turns_active >= turns_active_before_dissipating:
		on_destroy()
	else:
		trap_sprite.animation = "active"
		trap_sprite.play()
	
	turns_active += 1
