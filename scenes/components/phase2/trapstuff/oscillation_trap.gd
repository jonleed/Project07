extends Contact_Trap
class_name Oscillation_Trap

@export var turns_active:int = 2
@export var turns_inactive:int = 2
@export var turns_warming_up:int = 1
@export var turns_cooling_down:int = 1
@export var number_of_cycles:int = 99999 # Setting to INF led to overflow into negatives

@onready var trap_sprite:AnimatedSprite2D = $AnimatedSprite2D
var running_turn_clock:int = 0
var current_cycle:int = 0

func setup_trap_specific_variables() -> void:
	pass
	
func process_turn() -> void:
	if current_cycle >= number_of_cycles:
		is_functional = false
		has_activated = true
		return
	
	running_turn_clock += 1
	is_functional = false
	var modulous = running_turn_clock % (turns_active + turns_warming_up + turns_active + turns_cooling_down)
	if modulous <= turns_inactive:
		trap_sprite.animation = "inactive"
	elif modulous <= turns_inactive + turns_warming_up:
		trap_sprite.animation = "preparing"
	elif modulous <= turns_inactive + turns_warming_up + turns_active:
		trap_sprite.animation = "active"
		is_functional = true
	else:
		trap_sprite.animation = "cool_down"
	
	trap_sprite.play()
	
	if modulous == 0:
		current_cycle += 1
