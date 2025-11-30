extends Oscillation_Trap
class_name Fire_Trap

func setup_trap_specific_variables() -> void:
	trap_sprite.animation = "inactive"
	trap_sprite.play()
