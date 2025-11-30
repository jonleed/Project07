extends Time_Limited_Trap
class_name Fire


func setup_trap_specific_variables() -> void:
	trap_damage = 5
	trap_sprite.animation = "active"
	trap_sprite.play()
